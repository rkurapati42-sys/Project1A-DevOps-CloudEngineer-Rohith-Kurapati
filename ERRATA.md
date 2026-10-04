# NovaPay Assessment Errata

This file records the three deliberate technical errors required by the assessment.

## Part A — CI/CD Pipeline Error
The original pipeline referenced Gradle wrapper execution even though the application build is Maven-based. Correct implementation uses Maven with the committed pom.xml and Java 21.

## Part C — Compliance Error
A trusted-registry check was initially described as image-signature verification. Registry origin alone does not prove cryptographic signing. Production admission must verify the image signature using the approved signing/verification mechanism.

## Part D — Deployment Error
The initial canary configuration used a 10% starting weight and stopped before the required final 100% promotion. The corrected strategy follows the required progression: 1–2%, 5–10%, 25–50%, then 100%, with health gates and rollback criteria at each stage.

## Correction Principle
Errata corrections must be reflected in the implementation and validated before final submission.