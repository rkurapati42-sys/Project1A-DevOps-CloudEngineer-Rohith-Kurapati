package com.novapay.model;

import java.math.BigDecimal;

public record PaymentRequest(
        String fromAccount,
        String toAccount,
        BigDecimal amount
) {
}
