# PostgreSQL Infrastructure - mct-main (Production)

## Overview

PostgreSQL runs **natively on the host** (not in Docker) on `mct-main` (Oracle Linux 8).

- **Version**: PostgreSQL 13.23
- **Data dir**: `/var/lib/pgsql/data`
- **Port**: 5432
- **Max connections**: 100
- **Local auth**: `trust` (no password for `sudo -u postgres`)

## Quick Access (SSH)

```bash
# List databases
ssh mct-main "sudo -u postgres psql -c '\l'"

# Connect to specific DB
ssh mct-main "sudo -u postgres psql -d maiscashpro"

# Run query
ssh mct-main "sudo -u postgres psql -d maiscashpro -c 'SELECT count(*) FROM tablename;'"
```

## Databases

| Database | Size | Primary User | Purpose |
|----------|------|-------------|---------|
| **maiscashpro** | ~2 GB | `maiscashpro` | MaisCashPro main app (Spring Boot) |
| **consig1** | ~1.6 GB | `allapp` | Consig1MS + collectors + import/export |
| **op** | ~1.4 GB | `op` | Operations data |
| **maiscashtech** | ~513 MB | `bi_writer` / `bi_reader` | Business Intelligence / Metabase queries |
| **metabase_mct** | ~36 MB | `metabase` | Metabase internal metadata |
| **consig1dashboard** | ~10 MB | `consig1dashboard` | Consig1 dashboard app |

## Users (Roles)

| User | Superuser | Databases | Used by |
|------|-----------|-----------|---------|
| `postgres` | YES | all | Admin only |
| `allapp` | no | consig1 | Consig1MS, CollectorsMS, ImportMS, ExportMS, extrato workers |
| `maiscashpro` | no | maiscashpro, consig1 (read) | maiscashpro-app-1 container |
| `bi_reader` | no | consig1, maiscashtech, op, maiscashpro | Metabase read-only queries |
| `bi_writer` | no | maiscashtech | Metabase write (localhost only) |
| `consig1dashboard` | no | consig1dashboard | Consig1 dashboard frontend |
| `metabase` | no | metabase_mct | Metabase internal |
| `op` | no | op | Operations service |

## Schemas

| Database | Schema | Tables |
|----------|--------|--------|
| maiscashpro | `public` | 13 |
| consig1 | `consig1` | 16 |
| consig1 | `public` | 7 |
| consig1 | `usercontrol` | 72 |

## Service-to-Database Mapping

| Service (Container) | Database | User | Connection source |
|--------------------|----------|------|-------------------|
| maiscashpro-app-1 | maiscashpro | maiscashpro | 172.19.0.11 (Docker bridge) |
| maiscashpro-app-1 | consig1 (read) | maiscashpro | 172.19.0.11 |
| Consig1MS | consig1 | allapp | 172.19.0.x (Docker bridge) |
| Consig1CollectorsMS | consig1 | allapp | 172.19.0.x |
| Consig1ImportMS | consig1 | allapp | 172.19.0.x |
| Consig1ExportMS | consig1 | allapp | 172.19.0.x |
| extrato1-7 (mct-extrato) | consig1 | allapp | 10.0.0.28 (OCI internal) |

## pg_hba.conf Access Rules

```
local   all             all                          trust
host    consig1         allapp           0.0.0.0/0   md5
host    consig1         bi_reader        0.0.0.0/0   md5
host    consig1         maiscashpro      0.0.0.0/0   md5
host    consig1dashboard consig1dashboard 0.0.0.0/0   md5
host    maiscashpro     maiscashpro      0.0.0.0/0   md5
host    maiscashpro     bi_reader        0.0.0.0/0   md5
host    maiscashtech    bi_writer        127.0.0.1/32 md5
host    maiscashtech    bi_writer        ::1/128      md5
host    maiscashtech    bi_reader        0.0.0.0/0    md5
host    op              op               0.0.0.0/0    md5
host    op              bi_reader        0.0.0.0/0    md5
host    metabase_mct    metabase         0.0.0.0/0    md5
```

> `bi_writer` restricted to localhost only. All other users accept from any IP with md5 auth.

## Network Topology

```
mct-extrato (10.0.0.28) ──OCI internal──> mct-main:5432 (PostgreSQL native)
                                              ^
Docker containers (172.19.0.x) ──bridge──────┘
  - maiscashpro-app-1 (172.19.0.11)
  - Consig1MS, CollectorsMS, ImportMS, ExportMS, etc.
```

---
*Last verified: 2026-03-26 via SSH*
