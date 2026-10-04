# NovaPay Observability and Dashboards

## Objective
Use metrics, logs and traces to detect deployment problems quickly and support rollback and RCA.

## Core Metrics
### Application
- Request rate
- HTTP 4xx/5xx rate
- Transaction success rate
- p95/p99 latency

### Infrastructure
- CPU utilization
- Memory utilization
- Pod restarts
- OOM kills
- Readiness/liveness failures

### Database
- Connection pool utilization
- Active connections
- Query latency
- Database errors
- Lock/wait indicators

## Prometheus
Prometheus collects application and infrastructure metrics. Spring Boot Actuator exposes metrics through the Prometheus endpoint.

## Grafana Dashboard
Production dashboard should show request rate, error rate, p99 latency, transaction success, CPU, memory, pod health and database connection utilization.

## Deployment Monitoring
Compare stable and canary versions. Traffic must not progress when approved error, latency, transaction or infrastructure thresholds are breached.

## Alerts
- HTTP 5xx >5% for 60 seconds
- Three consecutive health-check failures
- OOM kills
- CrashLoopBackOff
- DB connection pool exhaustion
- p99 >2x baseline for 5 minutes
- Transaction success rate drop >2%

## Success Criteria
Metrics exist before deployment, dashboards are available to operators, alerts map to rollback triggers and evidence is retained for RCA.