---
name: performance-profiler
description: Profiles Python and JavaScript code to identify slow endpoints, inefficient queries, and memory leaks. Generates performance reports with bottlenecks, flame graphs, and optimization recommendations. Use when optimizing slow features, diagnosing performance regressions, or preparing for scaling.
---

# Performance Profiler

This skill identifies performance bottlenecks and generates optimization recommendations.

## When to use this skill

- Slow endpoints: "Why is this endpoint taking 5 seconds?"
- Query optimization: "Find N+1 queries"
- Memory leaks: "Debug memory growth"
- Load testing: "How many requests can we handle?"
- Optimization: "Where should we focus next?"

## How to use this skill

### Step 1: Run profiler

```bash
python .agent/skills/performance-profiler/scripts/profile_performance.py
```

Options:
- **Profile backend** - Python endpoints
- **Profile frontend** - JavaScript components
- **Database queries** - Query performance
- **Memory profiling** - Detect leaks
- **Load test** - Concurrent requests

### Step 2: Review report

Output shows:
- Slowest functions (with timing)
- Most memory-intensive operations
- Database query patterns
- N+1 query detection
- Flame graph visualization
- Recommendations

### Step 3: Optimize

Use findings to:
1. Add indexes (database)
2. Cache results (Redis)
3. Optimize queries (fewer selects)
4. Parallelize work
5. Reduce payload sizes

## Profiling Methods

### Method 1: Endpoint Timing

```bash
python profile_performance.py --endpoint /api/v1/clients/
```

Measures:
- Request processing time
- Database query time
- External API calls
- Response serialization

Example output:

```
Endpoint: POST /api/v1/clients/
  Total Time: 245ms  🟠 Slow

Breakdown:
  Authentication:    12ms  ✅ Fast
  Validation:        18ms  ✅ Fast
  Database:         180ms  🟠 Slow (73%)
    - INSERT client_company:  120ms
    - INSERT audit_log:        35ms
    - Commit transaction:      25ms
  Serialization:     15ms  ✅ Fast

Recommendations:
  1. Batch audit log inserts (save 35ms)
  2. Add database indexes on company_id (save 45ms)
  3. Use connection pooling (save 10ms)
```

### Method 2: Query Analysis

```bash
python profile_performance.py --queries
```

Detects:
- N+1 query patterns
- Slow queries (> 100ms)
- Missing indexes
- Sequential queries (parallelize)

Example output:

```
Query Performance Analysis:

🔴 N+1 DETECTED: list_clients_with_tools
   Pattern: Query clients → Loop query tools per client
   Location: app/services/client_service.py:45
   
   Bad:
   for client in clients:
       client.tools = get_tools(client.id)  ← Query per client!
   
   Fix: Use eager loading
   clients = select(Client).options(joinedload(Client.tools))

🟠 SLOW QUERY: client_contacts (425ms)
   SELECT c.* FROM contacts c
   WHERE c.company_id = 1
   
   Missing index: CREATE INDEX idx_contacts_company ON contacts(company_id)
   
   After index: ~25ms (16x faster)

✅ GOOD QUERY: list_tools (8ms)
   Properly indexed, using connection pooling
```

### Method 3: Memory Profiling

```bash
python profile_performance.py --memory --duration 60
```

Tracks:
- Memory growth over time
- Largest objects in memory
- Garbage collection overhead
- Memory swaps

Example output:

```
Memory Analysis (60 second run):

Total Allocated: 245 MB
Peak Memory: 312 MB
Final Memory: 198 MB

Memory by Module:
  app/models/: 98 MB  (40%)
  app/services/: 67 MB  (27%)
  fastapi/: 34 MB  (14%)
  other: 46 MB  (19%)

Largest Objects:
  List[ClientCompany]: 45 MB  (100 clients × 450 KB)
  Request cache: 23 MB
  Connection pool: 15 MB

Leaks Detected:
  ❌ request_cache not cleared: +2MB per request
     Location: app/middleware/auth.py:42
     Fix: Add cleanup in finally block

Recommendations:
  1. Use generators instead of list (save 45 MB)
  2. Implement request cache cleanup (save 2 MB/req)
  3. Reduce connection pool size (save 5 MB)
```

### Method 4: Load Testing

```bash
python profile_performance.py --load-test --concurrency 50 --duration 30
```

Simulates concurrent load:

```
Load Test: 50 concurrent users, 30 second duration

Total Requests: 1,250
Successful: 1,245 (99.6%)
Failed: 5 (0.4%)

Response Times:
  Min: 12ms
  Max: 8,450ms
  Mean: 245ms
  Median: 189ms
  P95: 720ms
  P99: 2,100ms

Throughput:
  Requests/sec: 41.7 req/s
  Bytes/sec: 12.4 MB/s

Bottlenecks:
  🟠 GET /api/v1/clients/ → 245ms average
  🟠 POST /api/v1/tools/execute → 1,200ms average (unstable)
  ✅ GET /api/v1/tools/ → 32ms average (well-optimized)

Resource Usage:
  CPU: 65% average
  Memory: 280 MB peak
  Database: 240 connections

Recommendations:
  1. Scale to 2-3 application instances
  2. Add caching for clients list
  3. Optimize tool execution (implement queues)
  4. Use read replicas for reports
```

## Report Formats

### Flame Graph

Visual representation of where time is spent:

```
    total: 245ms

    auth (12ms) ━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  12%

    db (180ms)   ━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━════════════════════
                    73%
    ├─ insert (120ms)
    ├─ index_lookup (35ms)
    └─ commit (25ms)

    serialize (15ms) ━━╋━━━━━━
                        6%

    other (38ms)  ━━╋━━━━━━━━━━━━━
                    15%
```

### CSV Export

For spreadsheet analysis:

```
function,calls,total_time_ms,avg_time_ms,max_time_ms
create_client,150,36750,245,1250
list_clients,200,8900,44.5,320
assign_tool,450,67500,150,890
execute_tool,80,96000,1200,8450
```

## Optimization Examples

### Problem 1: N+1 Queries

```python
# ❌ BAD - N+1 queries
async def list_clients_with_tools(db):
    clients = await db.execute(select(ClientCompany))
    for client in clients.scalars():
        tools = await db.execute(
            select(Tool).where(Tool.company_id == client.id)
        )
        client.tools = tools.scalars().all()  # ← Query per client!
    return clients

# ✅ GOOD - Single query with join
async def list_clients_with_tools(db):
    return await db.execute(
        select(ClientCompany).options(joinedload(ClientCompany.tools))
    )
```

**Impact**: 
- N clients + 1 query = N+1 total queries
- Optimize: 1 query total
- Speedup: 10x to 100x

### Problem 2: Missing Index

```python
# ❌ BAD - Full table scan
SELECT * FROM contacts WHERE company_id = 1

# ✅ GOOD - Indexed lookup
CREATE INDEX idx_contacts_company ON contacts(company_id);
SELECT * FROM contacts WHERE company_id = 1  ← Now uses index
```

**Impact**:
- Before: 425ms (full table scan 50k rows)
- After: 25ms (index lookup)
- Speedup: 17x

### Problem 3: Memory Bloat

```python
# ❌ BAD - Load all in memory
clients = await db.execute(select(ClientCompany))
all_clients = clients.scalars().all()  # ← All in memory
return all_clients

# ✅ GOOD - Use pagination
page = 1
limit = 50
offset = (page - 1) * limit
clients = await db.execute(
    select(ClientCompany).offset(offset).limit(limit)
)
return clients.scalars().all()
```

**Impact**:
- All clients (100K): 450 MB memory
- Paginated (50): 2.2 MB memory
- Ratio: 200x reduction

### Problem 4: Slow Validation

```python
# ❌ BAD - Validate in loop
for client in clients:
    validate_client(client)  ← Function call overhead

# ✅ GOOD - Bulk validation
validate_clients_bulk(clients)  ← Single pass
```

**Impact**: 30-50% faster for large lists

## Continuous Monitoring

Add profiling to CI/CD:

```bash
# Before deploying, check performance
python profile_performance.py --regression-check

# Fail if response times increased by >10%
# Fail if new N+1 queries detected
# Warn if memory usage increased by >5%
```

## Best Practices

✅ **Profile before optimizing** - Don't guess  
✅ **Measure with realistic data** - Scale matters  
✅ **Watch for regressions** - Monitor over time  
✅ **Optimize bottlenecks** - 80/20 rule applies  
✅ **Test after optimizing** - Ensure correctness  

❌ **Don't:**
- Premature optimization (profile first)
- Optimize without measurement
- Sacrifice readability for marginal gains
- Ignore external dependencies
- Forget cache invalidation

## See Also

- `code-quality-auditor` - Code quality affects performance
- `test-runner` - Performance testing
- `api-documentation-generator` - Document SLAs
- `permission-validator` - Ensure security doesn't hurt performance
