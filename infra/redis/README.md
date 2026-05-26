# Redis - MaisCash Infrastructure

Redis 7 instance for BullMQ job queues (used by digitador-rpa).

## Production (mct-main)

- **Container**: `redis` on `consig1` network
- **Port**: 6379
- **Persistence**: AOF (appendonly yes)
- **Memory limit**: 256MB with allkeys-lru eviction
- **Volume**: `redis-data` (Docker named volume)

## Jenkins Job

`redis - deploy` — pulls redis:7 image and runs container.
No build step needed (official image).
