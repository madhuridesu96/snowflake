# Day 2 Governance Note: Tags and Tag-Based Masking

## What is a Snowflake tag?

A tag is a label (for example `PII`) that can be attached to Snowflake objects such as databases, schemas, tables and columns, with a value like `'email'`. Tags don't change the data; they describe it, so sensitive data can be found, tracked and governed. Horizon Catalog uses tags for classification, and they can be searched across the whole account.

## How tag-based masking works

Instead of attaching a masking policy to each column one at a time, the policy is attached to the tag:

```sql
CREATE TAG pii;
ALTER TAG pii SET MASKING POLICY mask_email;
ALTER TABLE customers MODIFY COLUMN email SET TAG pii = 'email';
```

From then on, any column tagged `pii` (of the matching data type) is automatically protected by that policy, in any table, schema or database in the account. When a new table with an email column is created and tagged `pii`, it is masked immediately with no extra policy work.

## Why this scales better than table-by-table masking

- **One policy, many columns:** one rule is maintained centrally instead of hundreds of separate `SET MASKING POLICY` statements.
- **No gaps:** new tables are protected as soon as their columns are tagged, so nobody has to remember to add a policy to each new table.
- **Easy to change:** updating the policy once changes the behavior everywhere the tag is used.
- **Auditable:** Horizon Catalog shows every column tagged `pii`, so it is easy to prove where sensitive data lives and how it is protected.
- **Separation of duties:** security teams own the tags and policies, while data engineers only need to tag columns correctly.

## What I built today

- Custom roles `data_engineer` and `data_analyst`, both inheriting into `SYSADMIN`
- Least-privilege USAGE grants plus a future grant for SELECT on new bronze tables
- Masking policy `mask_email`: real emails for DATA_ENGINEER, `***MASKED***` for everyone else
- Row access policy `region_policy`: DATA_ENGINEER sees all 6 rows, DATA_ANALYST sees only the 3 EAST rows
- Verified both policies attached to `retail_lakehouse.bronze.customers` using `POLICY_REFERENCES`
