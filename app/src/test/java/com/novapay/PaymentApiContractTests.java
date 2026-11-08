package com.novapay;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class PaymentApiContractTests {

    @LocalServerPort
    private int port;

    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Test
    void paymentEndpointHonorsRequestAndResponseContract() throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://127.0.0.1:" + port + "/api/v1/payments"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString("""
                        {
                          "fromAccount": "ACC-1001",
                          "toAccount": "ACC-2002",
                          "amount": 125.50
                        }
                        """))
                .build();

        HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString());

        assertEquals(200, response.statusCode());
        assertTrue(response.headers().firstValue("Content-Type")
                .orElse("").contains("application/json"));
        assertTrue(response.body().contains("\"transactionId\""));
        assertTrue(response.body().contains("\"status\":\"SUCCESS\""));
        assertTrue(response.body().contains("\"fromAccount\":\"ACC-1001\""));
        assertTrue(response.body().contains("\"toAccount\":\"ACC-2002\""));
        assertTrue(response.body().contains("\"amount\":125.50"));
    }

    @Test
    void readinessEndpointExposesSpringBootProbeContract() throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://127.0.0.1:" + port + "/actuator/health/readiness"))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString());

        assertEquals(200, response.statusCode());
        assertTrue(response.body().contains("\"status\":\"UP\""));
    }
}
