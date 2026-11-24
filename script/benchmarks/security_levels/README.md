# Security level query benchmark

Measures what the security level visibility filter costs on work package queries.

`WorkPackages::Scopes::AllowedTo` resolves the user's projects, shared work packages and
security levels to id lists once per request, then adds one condition to the existing
visibility condition:

```sql
WHERE (work_packages.project_id IN (...) OR work_packages.id IN (...))   -- unchanged
  AND (work_packages.security_level_id IS NULL
       OR work_packages.security_level_id IN (...))                      -- new
```

No join and no subquery. PostgreSQL applies it as a row filter on tuples it already
fetched for the project condition, so the plan, the indexes used and the number of pages
read stay the same. The cost is one comparison per candidate row.

## Running it

Needs PostgreSQL and Python 3 (standard library only).

```sh
createdb secbench
psql -d secbench -f schema.sql
psql -d secbench -v wp_count=5000000 -v secured_share=0.2 -f seed.sql   # ~2 min
python3 run.py --db secbench --runs 15 [--explain]

# heavier security usage on the same data
psql -d secbench -v secured_share=0.8 -f assign_levels.sql
python3 run.py --db secbench --runs 15
```

`schema.sql` copies the `work_packages` columns and indexes from
`db/migrate/tables/work_packages.rb`. The seed puts 5M work packages into 2,000 projects,
skewed so that a few projects are very large. Every fourth project uses one of 20 schemes,
each with 3 levels. The benchmark user is a member of 101 projects (including the two
largest), has 50 work packages shared with them individually and holds 6 levels.

`run.py` times each query (median and p95 over N runs, inside PostgreSQL after a warm-up)
in three variants:

* **baseline**: today's visibility condition
* **with levels**: plus the security level condition
* **no levels**: plus the condition for a user who holds no level (`security_level_id IS NULL`)

It does this with no extra index, with a partial index on `security_level_id`, and with
a composite `(project_id, security_level_id)` index.

## Results

PostgreSQL 16, 4 vCPU, 16 GB RAM, `shared_buffers=4GB`, data fully cached. Times are
median ms. Sub-millisecond differences are within run-to-run noise.

### 20% of work packages in secured projects have a level (225k of 5M)

| query | baseline | with levels | no levels |
|---|---:|---:|---:|
| Q1 all open, newest first, page 1 | 0.40 | 0.42 | 0.40 |
| Q2 count of all open (770k visible) | 1036 | 1121 | 1191 |
| Q3 biggest project by updated_at, page 1 | 0.36 | 0.39 | 0.37 |
| Q4 biggest secured project by updated_at, page 1 | 0.36 | 0.73 | 0.37 |
| Q5 assigned to me | 0.84 | 0.91 | 0.86 |
| Q6 group by status with sums | 952 | 945 | 936 |
| Q7 overdue, sorted by due date | 2.12 | 2.15 | 2.15 |

### 80% of work packages in secured projects have a level (904k of 5M)

| query | baseline | with levels | no levels |
|---|---:|---:|---:|
| Q1 | 0.39 | 0.41 | 0.41 |
| Q2 | 909 | 1014 | 1022 |
| Q3 | 0.37 | 0.48 | 0.36 |
| Q4 | 0.40 | 0.42 | 0.41 |
| Q5 | 1.00 | 0.84 | 0.88 |
| Q6 | 893 | 928 | 926 |
| Q7 | 2.21 | 2.45 | 2.50 |

What the numbers show:

* **Paginated lists** (what the work package table, boards and the API fetch): the change
  is a few hundredths of a millisecond, within noise. Example Q4: the plan is the same
  index scan, it removes 4 rows by filter and reads 39 instead of 35 buffers.
* **Full aggregates** over hundreds of thousands of rows (counts, sums, group-by): +0–11%.
  `EXPLAIN (ANALYZE, BUFFERS)` shows the same plan and the **same number of pages read**
  (247,935 for Q2 in both variants). The only difference is an extra `Filter:` line. These
  queries are slow because of the number of visible rows, before and after the change.
* **Indexes:** no index on `security_level_id` improved the visibility queries. The
  composite index only helps a user who holds no level at all; then it can halve the
  aggregates.

### Index decision

The migration adds a partial index:

```ruby
add_index :work_packages, :security_level_id, where: "security_level_id IS NOT NULL"
```

It doesn't help the visibility filter, but it is needed for:

* the `ON DELETE SET NULL` foreign key when a level is deleted: 2.3 s sequential scan
  without the index, index scan with it (5M rows);
* per-level lookups, and the "work packages hidden from this user" anti-join used by the
  journal timeline.

It only contains secured rows: 6 MB here, against 48 MB for `work_packages_project_id_idx`.

## Repeating it on real data

The synthetic distribution is the weak point of this benchmark. To confirm on a production
dump:

1. Anonymize a large customer or SaaS dump (`script/anonymize-sql-dump`) and run the
   migration.
2. Give levels to work packages in the proportion the Jira source uses (Jira:
   `SELECT security, count(*) FROM jiraissue GROUP BY 1`).
3. Turn on `pg_stat_statements` and replay the same set of saved queries as a few real users
   (for example the default views and the slowest saved views from `queries`) with the
   condition and without it. Compare `mean_exec_time` and `shared_blks_hit + shared_blks_read`.
   If the buffer counts match, the overhead is the per-row filter only.

The specs in `spec/models/security_levels/work_package_visibility_spec.rb` keep the SQL in
this shape: they fail if the level tables get joined or the levels are looked up more than
once per user instance.
