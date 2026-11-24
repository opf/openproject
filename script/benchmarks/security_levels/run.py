#!/usr/bin/env python3
"""
Compares OpenProject-style work package queries with and without the security level
visibility predicate. Requires a database prepared with schema.sql + seed.sql.

  python3 run.py --db secbench [--runs 30] [--explain]
"""
import argparse
import random
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--db", default="secbench")
parser.add_argument("--runs", type=int, default=30)
parser.add_argument("--explain", action="store_true", help="print EXPLAIN ANALYZE for every query")
args = parser.parse_args()


def psql(sql):
    out = subprocess.run(["psql", "-X", "-qAt", "-F", "|", "-d", args.db, "-c", sql],
                         check=True, capture_output=True, text=True)
    return out.stdout.strip()


def ids(sql):
    return [int(x) for x in psql(sql).split("\n") if x]


def in_list(values):
    return "(" + ",".join(str(v) for v in values) + ")" if values else "(NULL)"


psql(open(__file__.replace("run.py", "timing.sql")).read())
random.seed(7)

# A regular user: member of 100 projects (the two biggest included), 50 work packages shared
# with them individually and 6 security levels (direct + via groups) - the ids OpenProject
# plucks once per request in WorkPackages::Scopes::AllowedTo.
project_ids = sorted({1, 2} | set(random.sample(range(3, 2001), 98)))
shared_wp_ids = sorted(random.sample(range(1, int(psql("SELECT max(id) FROM work_packages"))), 50))
level_ids = ids("SELECT id FROM security_levels ORDER BY id LIMIT 18")[::3]
big_secured_project = int(psql("""SELECT project_id FROM work_packages w JOIN projects p ON p.id = w.project_id
                                 WHERE p.security_level_scheme_id IS NOT NULL
                                 GROUP BY 1 ORDER BY count(*) DESC LIMIT 1"""))
if big_secured_project not in project_ids:
    project_ids.append(big_secured_project)

visible = f"(work_packages.project_id IN {in_list(project_ids)} OR work_packages.id IN {in_list(shared_wp_ids)})"
security = (f"(work_packages.security_level_id IS NULL OR "
            f"work_packages.security_level_id IN {in_list(level_ids)})")
security_none = "work_packages.security_level_id IS NULL"

open_statuses = "(1,2,3,4,5,6)"
QUERIES = {
    "Q1 all open WPs, newest first, page 1": lambda v: f"""
        SELECT * FROM work_packages WHERE {v} AND status_id IN {open_statuses}
        ORDER BY id DESC LIMIT 20""",
    "Q2 count of all open WPs": lambda v: f"""
        SELECT count(*) FROM work_packages WHERE {v} AND status_id IN {open_statuses}""",
    "Q3 biggest project, by updated_at, page 1": lambda v: f"""
        SELECT * FROM work_packages WHERE {v} AND project_id = 1
        ORDER BY updated_at DESC LIMIT 20""",
    "Q4 biggest secured project, by updated_at": lambda v: f"""
        SELECT * FROM work_packages WHERE {v} AND project_id = {big_secured_project}
        ORDER BY updated_at DESC LIMIT 20""",
    "Q5 assigned to me": lambda v: f"""
        SELECT * FROM work_packages WHERE {v} AND assigned_to_id = 42
        ORDER BY id DESC LIMIT 20""",
    "Q6 group by status (sums)": lambda v: f"""
        SELECT status_id, count(*), sum(estimated_hours) FROM work_packages WHERE {v} GROUP BY status_id""",
    "Q7 overdue, sorted by due date": lambda v: f"""
        SELECT * FROM work_packages WHERE {v} AND due_date < date '2025-06-01' AND status_id IN {open_statuses}
        ORDER BY due_date, id LIMIT 20""",
}

VARIANTS = {
    "baseline": visible,
    "levels": f"{visible} AND {security}",
    "no levels": f"{visible} AND {security_none}",
}

INDEXES = {
    "no extra index": [],
    "idx(security_level_id) partial": [
        "CREATE INDEX bench_idx1 ON work_packages (security_level_id) WHERE security_level_id IS NOT NULL"],
    "idx(project_id, security_level_id)": [
        "CREATE INDEX bench_idx2 ON work_packages (project_id, security_level_id)"],
}


def bench(sql):
    return psql(f"SELECT * FROM bench($q${sql}$q$, {args.runs})").split("|")


def rows(sql):
    return psql(f"SELECT count(*) FROM ({sql}) x")


stats = psql("""SELECT count(*), count(security_level_id),
                       (SELECT count(*) FROM projects WHERE security_level_scheme_id IS NOT NULL)
                FROM work_packages""").split("|")
print(f"work packages: {int(stats[0]):,}, with a security level: {int(stats[1]):,}, "
      f"projects with a scheme: {stats[2]}/2000")
print(f"user: {len(project_ids)} projects, {len(shared_wp_ids)} shared WPs, levels {level_ids}; "
      f"biggest secured project: {big_secured_project}")
print(f"visible WPs baseline: {int(rows('SELECT 1 FROM work_packages WHERE ' + visible)):,}; "
      f"with levels: {int(rows('SELECT 1 FROM work_packages WHERE ' + VARIANTS['levels'])):,}\n")

for index_name, ddl in INDEXES.items():
    psql("DROP INDEX IF EXISTS bench_idx1; DROP INDEX IF EXISTS bench_idx2;")
    for stmt in ddl:
        psql(stmt)
    psql("ANALYZE work_packages")
    print(f"=== {index_name} ===")
    print(f"{'query':45} {'baseline':>18} {'with levels':>18} {'no levels':>18} {'delta':>8}")
    for name, build in QUERIES.items():
        results = {v: bench(build(cond)) for v, cond in VARIANTS.items()}
        base = float(results["baseline"][0])
        lvl = float(results["levels"][0])
        delta = (lvl - base) / base * 100 if base else 0
        cells = " ".join(f"{r[0]:>8} ({r[1]:>7})" for r in results.values())
        print(f"{name:45} {cells} {delta:>+7.1f}%")
        if args.explain:
            for v in ("baseline", "levels"):
                print(f"--- {v}")
                print(psql(f"EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) {build(VARIANTS[v])}"))
    print("(median ms, p95 ms in parentheses)\n")
