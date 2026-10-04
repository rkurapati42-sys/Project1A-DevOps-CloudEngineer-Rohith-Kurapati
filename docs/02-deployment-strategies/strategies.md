# NovaPay Deployment Strategies

## Objective

NovaPay uses zero-downtime deployment strategies to release application changes safely while maintaining availability and providing rapid rollback.

## Supported Strategies

1. Blue-Green Deployment
2. Canary Deployment

## Blue-Green Deployment

Blue-Green deployment maintains two production environments:

- Blue — current active production version
- Green — new release candidate

The inactive environment is deployed and validated before production traffic is switched.

### Production Topology

```text
Ingress / Load Balancer
          |
    Traffic Routing
       /        \
     BLUE      GREEN
   Version N  Version N+1
       \        /
        \      /
     Shared Database
