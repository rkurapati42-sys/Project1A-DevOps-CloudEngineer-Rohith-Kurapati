package com.novapay.service;

import com.novapay.model.PaymentRequest;
import com.novapay.model.PaymentResponse;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class PaymentService {

    public PaymentResponse processPayment(PaymentRequest request) {

        String transactionId = UUID.randomUUID().toString();

        return new PaymentResponse(
                transactionId,
                "SUCCESS",
                request.fromAccount(),
                request.toAccount(),
                request.amount()
        );
    }
}
