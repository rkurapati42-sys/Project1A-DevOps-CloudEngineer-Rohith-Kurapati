package com.novapay.model;

import java.math.BigDecimal;

public record PaymentResponse(
        String transactionId,
        String status,
        String fromAccount,
        String toAccount,
        BigDecimal amount
) {
}
