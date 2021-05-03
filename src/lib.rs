/*
 * Copyright 2021 OpenTelemetry Injector Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

extern crate libc;

#[macro_use] extern crate redhook;

use crate::OpenTelemetryInjectorError::JavaAgentNotFound;
use crate::OpenTelemetryInjectorError::JavaAgentNotSet;

use libc::c_char;
use log::{debug, error, LevelFilter};
use simple_logger::SimpleLogger;
use std::{env,fmt,fs};
use std::ffi::{CStr,CString};
use std::io::Read;
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::Once;

static INITIALIZATION: Once = Once::new();

static mut IS_DEBUG : bool = false;
static mut JAVA_AGENT_PATH : Result<PathBuf, OpenTelemetryInjectorError> = Err(JavaAgentNotSet);

use serde_derive::Deserialize;

#[derive(Deserialize)]
struct Configuration {
    jvm: Option<JVM>,
}

#[derive(Deserialize)]
struct JVM {
    agent_path: Option<String>,
}

pub enum OpenTelemetryInjectorError {
    JavaAgentNotSet, // No configuration available
    JavaAgentNotFound(String), // Configuration available but invalid, contains configured path
}

impl fmt::Display for OpenTelemetryInjectorError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match &*self {
            JavaAgentNotSet => write!(f, "'jvm.agent_path' is not set in the configuration"),
            JavaAgentNotFound(path) => write!(f, "the configured JVM agent path '{}' cannot be opened", &path),
        }
    }
}

unsafe fn append_java_agent(original_value: &str, otel_javaagent_path: &str) -> String {
    let mut result = format!("-javaagent:{}", otel_javaagent_path).to_string();

    if !original_value.is_empty() {
        result.push_str(" ");
        result.push_str(original_value);
    }

    result        
}

hook! {
    unsafe fn getenv(s: *const c_char) -> *mut c_char => inject_otel_trigger {
        INITIALIZATION.call_once(|| {
            let mut so_location = None;
            let mut configuration_file_option : Option<PathBuf> = None;

            for (key, value) in env::vars_os() {
                match key.to_str() {
                    Some("LD_PRELOAD") => {
                        // FIXME LD_PRELOAD is space separated, in case of multiple ones we should take the first?
                        so_location = Some(PathBuf::from(value));
                    },
                    Some("OPENTELEMETRY_INJECTOR_DEBUG") => {
                        if let Ok(true) = FromStr::from_str(value.to_str().unwrap()) {
                            IS_DEBUG = true;
                        }
                    },
                    Some("OPENTELEMETRY_INJECTOR_CONFIGURATION") => {
                        configuration_file_option = Some(PathBuf::from(value));
                    },
                    _ => (),
                }
            }

            SimpleLogger::new().with_level(match IS_DEBUG {
                true => LevelFilter::Debug,
                false => LevelFilter::Info,
            }).init().unwrap();

            let configuration_file: &str = &(match configuration_file_option {
                Some(path) => path.to_str().unwrap().to_string(),
                None => {
                    let mut value: PathBuf = match so_location {
                        Some(path) => path,
                        None => PathBuf::from("/etc/ld.so.preload"),
                    };

                    // Look for the opentelemetry_injector.toml in the same location as the so file
                    value.pop();
                    value.push("/etc/opentelemetry/injector/configuration.toml");

                    value.to_str().unwrap().to_string()
                }
            });

            if IS_DEBUG {
                debug!("Configuration file location: {}", configuration_file);
            }

            let configuration: Configuration = match fs::File::open(configuration_file) {
                Ok(mut file) => {
                    let mut configuration_buffer = Vec::new();
                    file.read_to_end(&mut configuration_buffer).unwrap();

                    let configuration_content: &str = &String::from_utf8(configuration_buffer).unwrap();
                    let configuration: Configuration = toml::from_str(configuration_content).unwrap();

                    configuration
                },
                Err(error) => {
                    if IS_DEBUG {
                        debug!("Cannot open configuration file '{}': {}", configuration_file, error);
                    }

                    Configuration{
                        jvm: None
                    }
                },
            };

            JAVA_AGENT_PATH = match configuration.jvm {
                Some(jvm) => {
                    match jvm.agent_path {
                        Some(path) => {
                            // Check file exists, otherwise we will brick the JVM
                            match fs::File::open(&path) {
                                Ok(_file) => Ok(PathBuf::from(&path)),
                                Err(_error) => Err(JavaAgentNotFound(path)),
                            }
                        },
                        None => Err(JavaAgentNotSet),
                    }
                },
                None => Err(JavaAgentNotSet),
            }
        });

        let original_value = real!(getenv)(s);
        let mut result_value = original_value;

        if let Ok(env_var_name) = CStr::from_ptr(s).to_str() {
            match env_var_name {
                "JAVA_TOOL_OPTIONS" => {
                    let original_value = if original_value.is_null() { "" } else { CStr::from_ptr(original_value).to_str().unwrap() };

                    match JAVA_AGENT_PATH.as_ref() {
                        Ok(path) => {
                            if let Some(otel_javaagent_path) = path.to_str() {
                                let new_value = append_java_agent(&original_value, otel_javaagent_path);
                                if let Ok(new_value) = CString::new(new_value) {
                                    let new_value = new_value.into_raw();
                                    // Prevent Rust from cleaning up the value, or the surrounding program will not be able to read it
                                    std::mem::forget(new_value);
                                    result_value = new_value;
                                }            
                            }
                        },
                        Err(error) => {
                            error!("Cannot inject JVM agent: {}", error);
                        },
                    }
                },
                _ => (), // Nothing to do
            }
        }

        result_value
    }

}