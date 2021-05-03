package mmanciop.otel.injector.test.javatestapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@RestController
	@RequestMapping(path="/api")
	static class ApiController {

		@GetMapping(path="/greeting")
		public String greet() {
			return "Hello!";
		}

	}

}
