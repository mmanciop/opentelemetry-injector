package mmanciop.otel.injector.demo.serverapp;

import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class Application {

	private static final Logger LOGGER = LoggerFactory.getLogger(Application.class);

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@RestController
	@RequestMapping(path="/api")
	static class ApiController {

		private final AtomicInteger requestsCount = new AtomicInteger();

		@GetMapping(path="/greeting")
		public String greet() {
			final int count = requestsCount.incrementAndGet();
			if (count % 10 == 0) {
				LOGGER.info("Serving request #{}", count);
			}

			return "Hello!";
		}

	}

}
