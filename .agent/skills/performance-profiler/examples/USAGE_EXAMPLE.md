# Performance Profiler - Usage Examples

## Quick Start

### Profile Specific Endpoint

```bash
cd .agent/skills/performance-profiler
python scripts/profile_performance.py

# Select: 1 (Profile specific endpoint)
# Endpoint path: /api/v1/clients/
```

**Output:**
```
╔════════════════════════════════════════════════════════════════╗
║        Performance Profiler - ESG Sustainify                  ║
║                                                                ║
║  Profile code to identify bottlenecks and optimize            ║
╚════════════════════════════════════════════════════════════════╝

📊 Profiling endpoint: /api/v1/clients/
============================================================

Total Time: 187ms

Breakdown:
  Authentication: 9ms  (✅ Fast)
  Validation:     8ms  (✅ Fast)
  Database:       152ms  (🟠 Slow) — 81%
  Serialization:  18ms  (✅ Fast)

💡 Recommendations:
  1. Optimize database queries (consuming 81% of time)
  2. Add indexes on frequently filtered columns
  3. Check for N+1 query patterns
```

### Database Query Analysis

```bash
python scripts/profile_performance.py

# Select: 2 (Analyze database queries)
```

**Output - N+1 Pattern Detected:**
```
🔴 N+1 PATTERN DETECTED
────────────────────────────────────────────────────────────
Location: app/services/client_service.py:45
Pattern: Query clients → Loop query tools per client

Current (BAD):
  clients = get_all_clients()          # 1 query
  for client in clients:
    tools = get_tools(client.id)       # 1 query per client

Impact: 1 + N queries (slow for large N)

Fix: Use eager loading
  clients_with_tools = db.execute(
    select(Client).options(joinedload(Client.tools))
  )

Impact: 1-2 queries total (16x faster)
```

## Endpoint Profiling

### Profile All Endpoints

```bash
python scripts/profile_performance.py

# Select: 1 (Profile specific endpoint)
# Run multiple times with different endpoints

Endpoints to test:
  /api/v1/clients/           → Read list
  /api/v1/clients/1/         → Read one
  /api/v1/clients/           → Create
  /api/v1/clients/1/  (PUT)  → Update
  /api/v1/users/             → Complex query
```

### Timing Analysis

```
FAST (<50ms):
  ✅ GET /api/v1/tools/                      32ms
  ✅ GET /api/v1/clients/1/                  45ms

ACCEPTABLE (50-150ms):
  🟠 GET /api/v1/clients/                    127ms
  🟠 POST /api/v1/clients/                   89ms

SLOW (>150ms):
  🔴 POST /api/v1/tools/execute              1,200ms
  ✅ (Justifiable if heavy computation)
```

## Query Analysis

```bash
python scripts/profile_performance.py

# Select: 2 (Analyze database queries)
```

### Example: N+1 Prevention

**BEFORE (N+1 problem):**
```python
# app/services/client_service.py
async def get_all_clients(db: AsyncSession):
    clients = await db.execute(select(Client))
    for client in clients:
        # This runs N additional queries!
        tools = await db.execute(
            select(Tool).where(Tool.client_id == client.id)
        )
        client.tools = tools
    return clients

# Query pattern:
# 1. SELECT * FROM clients                    (1 query)
# 2-N. SELECT * FROM tools WHERE client_id=?  (N queries)
# Total: 1 + N queries
```

**AFTER (eager loading):**
```python
async def get_all_clients(db: AsyncSession):
    result = await db.execute(
        select(Client).options(joinedload(Client.tools))
    )
    return result.scalars().unique().all()
    
# Query pattern:
# 1. SELECT clients.*, tools.* FROM clients 
#    LEFT JOIN tools ON ...  (1-2 queries)
# Total: 1-2 queries
# Performance: 16x faster!
```

### Index Optimization

**BEFORE:**
```
Query: SELECT * FROM contacts WHERE company_id = 1
Execution Plan: Full Table Scan
  Rows scanned: 50,000
  Time: 425ms  ❌
```

**AFTER:**
```sql
CREATE INDEX idx_contacts_company ON contacts(company_id);
```

```
Query: SELECT * FROM contacts WHERE company_id = 1
Execution Plan: Index Lookup
  Rows scanned: 47
  Time: 25ms  ✅ (17x faster)
```

## Memory Profiling

```bash
python scripts/profile_performance.py

# Select: 3 (Memory profiling)
```

**Output:**
```
📊 Memory Profile Analysis
===================================

Memory Usage by Module:
  app/models/        98 MB   (40%)
  app/services/      67 MB   (27%)
  fastapi/           34 MB   (14%)
  other              46 MB   (19%)
───────────────────────────────────
  TOTAL             245 MB

🔴 MEMORY LEAK DETECTED
────────────────────────────────────────────────────────────
Location: app/middleware/auth.py:42
Issue: Request cache not cleared
Impact: +2MB per request

Fix: Add cleanup in finally block
  try:
    process_request()
  finally:
    clear_request_cache()  # ← Add this
```

### Memory Leak Detection

**BEFORE (memory grows):**
```python
# app/middleware/auth.py
request_cache = {}

@app.middleware("http")
async def auth_middleware(request, call_next):
    token = extract_token(request)
    request_cache[request.id] = token  # ← Never cleared!
    response = await call_next(request)
    return response

# Result:
# Request 1: 245 MB
# Request 2: 247 MB (+2MB)
# Request 3: 249 MB (+2MB)
# ...every request adds 2MB!
```

**AFTER (fixed):**
```python
@app.middleware("http")
async def auth_middleware(request, call_next):
    token = extract_token(request)
    request_cache[request.id] = token
    try:
        response = await call_next(request)
    finally:
        del request_cache[request.id]  # ← Clean up!
    return response

# Result:
# Request 1: 245 MB
# Request 2: 245 MB (stable)
# Request 3: 245 MB (stable)
```

## Load Testing

```bash
python scripts/profile_performance.py

# Select: 4 (Load testing)
```

**Output - Simulate 50 Concurrent Users:**
```
📊 Load Test Results (50 concurrent users, 30 seconds)
============================================================

Request Statistics:
  Total Requests:     1,250
  Successful:         1,245  (99.6%)
  Failed:             5      (0.4%)

Response Times:
  Min:        12ms     ✅
  Max:        8,450ms  🔴
  Mean:       245ms    🟠
  Median:     189ms    ✅
  P95:        720ms    🟠
  P99:        2,100ms  🔴

Throughput: 41.7 req/s

⚠️  Bottlenecks Detected:
  🟠 GET /api/v1/clients/        → 245ms avg (slow)
  🔴 POST /api/v1/tools/execute → 1,200ms avg (very slow)
  ✅ GET /api/v1/tools/         → 32ms avg (optimized)
```

### Understanding Load Test Results

**P95 = 95th Percentile:**
- 95% of requests complete within 720ms
- 5% take longer
- Target: < 500ms for user-facing endpoints

**P99 = 99th Percentile:**
- 99% of requests complete within 2,100ms
- 1% very slow (problems)
- Target: < 1,000ms (acceptable)

**Throughput:**
- 41.7 requests per second
- With 50 users = ~1 req per user per second
- Scale up load until throughput plateaus

## Complete Performance Report

```bash
python scripts/profile_performance.py

# Select: 5 (Generate full report)
```

Generates comprehensive analysis with:
1. ✅ Endpoint profiling (all times)
2. ✅ N+1 detection
3. ✅ Missing index identification
4. ✅ Memory leak warnings
5. ✅ Load testing results
6. 💾 Saved to `reports/performance-report.html`

## Real-World Optimization Example

### Scenario: List Clients Endpoint Slow (250ms)

**Step 1: Profile endpoint**
```bash
python profile_performance.py
# Select: 1, Enter: /api/v1/clients/
```

Result: Database consuming 210ms (84%)

**Step 2: Analyze queries**
```bash
python profile_performance.py
# Select: 2 (Analyze database queries)
```

Result: Found N+1 pattern in client_service

**Step 3: Fix code**
```python
# BEFORE
async def get_all_clients(db):
    clients = await db.execute(select(Client))
    for client in clients:
        contacts = await db.execute(select(Contact).where(...))
        # ... N queries!

# AFTER
async def get_all_clients(db):
    return await db.execute(
        select(Client).options(joinedload(Client.contacts))
    )
```

**Step 4: Re-profile**
```bash
python profile_performance.py
# Select: 1, Enter: /api/v1/clients/
```

Result: Database now 45ms (19x faster!)

Total time: 250ms → 65ms ✅

## Optimization Patterns

### Pattern 1: Eager Loading

```python
# List entities with nested data
select(Client).options(
    joinedload(Client.contacts),
    joinedload(Client.tools)
)
```

### Pattern 2: Pagination

```python
# Don't load all data
skip = (page - 1) * limit
query = select(Client).offset(skip).limit(limit)
```

### Pattern 3: Selective Columns

```python
# Load only needed fields
select(Client.id, Client.name, Client.industry)
```

### Pattern 4: Caching

```python
# Cache frequently accessed data
@cache.cached(timeout=300)
async def get_tools():
    return await db.execute(select(Tool))
```

## CI/CD Integration

Run profiling in pipeline:

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on: [pull_request]

jobs:
  perf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Profile Endpoints
        run: |
          cd backend
          pip install -r requirements.txt
          python ../.agent/skills/performance-profiler/scripts/profile_performance.py <<< "5"
      
      - name: Upload Report
        uses: actions/upload-artifact@v2
        with:
          name: performance-report
          path: reports/performance-report.html
      
      - name: Check Thresholds
        run: |
          # Fail if P95 > 500ms
          grep -q "P95.*[5-9][0-9][0-9]ms\|P95.*[1-9][0-9][0-9][0-9]ms" \
            reports/performance-report.html && exit 1 || exit 0
```

## Success Criteria

✅ Endpoint response times:
  - Fast (<50ms): GET single, GET simple lists
  - Acceptable (50-150ms): Complex queries, multiple JOINs
  - Slow (>150ms): Heavy computation (tools, reports)

✅ No N+1 queries detected
✅ No memory leaks
✅ P95 < 500ms under normal load
✅ Throughput > 30 req/s per core

## Troubleshooting

### Issue: "Profile shows slow database"

Check 1: N+1 queries detected?
```bash
python profile_performance.py
# Select: 2 (Analyze database queries)
```

Check 2: Missing indexes?
```sql
EXPLAIN ANALYZE SELECT * FROM clients WHERE company_id = 1;
-- Look for "Seq Scan" → missing index alert
```

Check 3: Full table scans?
```sql
CREATE INDEX idx_name ON table(columns);
```

### Issue: "Load test shows timeouts"

Solution: Increase database connections

```python
# backend/app/core/database.py
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,  # Increase from 5
    max_overflow=10
)
```

### Issue: "Memory keeps growing"

Solution: Find and fix memory leak

```python
# Check for uncleaned resources
# 1. Ensure session cleanup in finally blocks
# 2. Clear request caches
# 3. Close file handles
```

## Best Practices

✅ **DO**:
- Profile before and after changes
- Test under realistic load
- Fix N+1 patterns immediately
- Monitor P99 latency
- Use pagination for lists

❌ **DON'T**:
- Ignore slow endpoints
- Hardcode query limits
- Skip index on foreign keys
- Cache without TTL
- Ignore memory growth

Profile early, optimize often!
