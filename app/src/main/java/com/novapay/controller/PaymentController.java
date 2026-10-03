package com.novapay.controller;

import com.novapay.model.PaymentRequest;
import com.novapay.model.PaymentResponse;
import com.novapay.service.PaymentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping
    public ResponseEntity<PaymentResponse> createPayment(
            @RequestBody PaymentRequest request) {

        PaymentResponse response =
                paymentService.processPayment(request);

        return ResponseEntity.ok(response);
    }
}
