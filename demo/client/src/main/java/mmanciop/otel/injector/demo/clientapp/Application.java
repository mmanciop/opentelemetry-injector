package mmanciop.otel.injector.demo.clientapp;

import java.net.ConnectException;
import java.time.Duration;
import java.util.Objects;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.web.reactive.function.client.WebClient;

import reactor.core.publisher.Flux;

@SpringBootApplication
public class Application implements CommandLineRunner {

	private static final Logger LOGGER = LoggerFactory.getLogger(Application.class);

	public static void main(String[] args) {
		new SpringApplicationBuilder(Application.class)
			.web(WebApplicationType.NONE)
			.run(args);
	}

	private final String serverUrl;

	Application(@Value("${SERVER_URL}") final String serverUrl) {
		if (serverUrl.trim().isEmpty()) {
			throw new IllegalArgumentException("The 'SERVER_URL' is not set or its value is blank");
		}

		this.serverUrl = serverUrl;
	}

	@Override
	public void run(final String... args) throws Exception {
		final WebClient client = WebClient.create();

		final AtomicInteger requestsSuccessCounter = new AtomicInteger();
		final AtomicInteger connectionFailureCounter = new AtomicInteger();

		Flux.interval(Duration.ofMillis(100))
			.map(ignored -> UUID.randomUUID())
			.flatMap(requestId -> {
				return client.get()
					.uri(serverUrl + "?request_id=" + requestId)
					.retrieve()
					.toBodilessEntity();
			})
			.onErrorContinue(ConnectException.class, (exception, result) -> {
				final int currentAttempt = connectionFailureCounter.incrementAndGet();
				if (currentAttempt % 10 == 0) {
					LOGGER.error("Cannot connect to URL: {} (attempt {})", serverUrl, currentAttempt);
				}
			})
			.onErrorContinue(Exception.class, (exception, result) -> {
				if (Objects.nonNull(exception)) {
					LOGGER.error("Request failed", exception);
				}
			})
			.doOnNext(ignored -> {
				final int count = requestsSuccessCounter.incrementAndGet();
				if (count % 10 ==0) {
					LOGGER.info("Successful request count: {}", count);
				}
			})
			.blockLast();

		LOGGER.error("Client shutting down");
	}

}
