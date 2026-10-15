# Day 3: Data Protection in Snowflake

Time Travel, Fail-safe and zero-copy cloning all build on the same idea: Snowflake stores data in immutable micro-partitions, so older versions can be kept and shared instead of overwritten.

## Comparison

| | Time Travel | Fail-safe | Zero-copy cloning |
|---|---|---|---|
| **What it is** | Query or restore data as it was at an earlier point | Last-resort recovery period after Time Travel ends | Instant copy of a table, schema or database |
| **Who can use it** | You, with SQL (`AT`, `BEFORE`, `UNDROP`) | Snowflake Support only | You, with SQL (`CLONE`) |
| **How long** | 1 day by default; up to 90 days on Enterprise Edition and above (Standard: max 1 day) | 7 days for permanent tables, after Time Travel ends | Until you drop the clone |
| **Storage cost** | Changed or deleted data is kept for the retention period | Kept for 7 days (billed) | No extra storage at creation; only changed micro-partitions are stored separately (copy-on-write) |
| **Typical use** | Undo a bad UPDATE or DELETE, recover a dropped table, audit past values | Disaster recovery when Time Travel can no longer help | Dev/test environments, safe experiments, point-in-time snapshots |

Transient and temporary tables have no Fail-safe and at most 1 day of Time Travel.

## When I'd reach for each

- **Time Travel:** someone ran a wrong UPDATE or DELETE, or dropped a table by mistake. Use `BEFORE(STATEMENT => '<query_id>')` to see the data before the bad statement, or `UNDROP TABLE` to bring back a dropped table instantly.
- **Fail-safe:** only when the Time Travel window has already passed and data must be recovered. It isn't self-service, so it means opening a ticket with Snowflake Support. It's a safety net, not a backup strategy.
- **Zero-copy cloning:** when I need a full, independent copy to test changes safely, for example cloning the bronze schema before trying a new transformation. It's instant and free at creation, and can be combined with Time Travel (`CLONE ... AT(...)`) to copy data as it was at a past point.

## What I did today

- Changed a customer row and viewed the old value with `AT(OFFSET => -60)` and `BEFORE(STATEMENT => ...)`
- Dropped the customers table and recovered it with `UNDROP TABLE`
- Cloned the bronze schema to `bronze_clone`, edited a row in the clone, and confirmed the original was unchanged
- Loaded nested JSON into a VARIANT column, queried it with dot notation, and exploded line items with FLATTEN
- Checked clustering on a 1.5M-row orders table and noted why a clustering key is premature at that size
