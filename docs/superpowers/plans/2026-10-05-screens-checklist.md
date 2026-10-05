# Screens — Task Checklist

Plan: [2026-10-05-screens.md](2026-10-05-screens.md) · Spec: [../specs/2026-10-05-screens-design.md](../specs/2026-10-05-screens-design.md) · Idea: [idea-03](../../ideas/idea-03.md) · Branch: `claude/affectionate-ramanujan-2th1uy`

> Môi trường tác giả: Ruby 3.3.6 (repo cần 4.0.7), không Postgres/Docker/node_modules ⇒ chưa task nào được chạy. Mỗi task phải có dòng **Verification** (lệnh, exit status, pass/fail dán nguyên văn). Chưa chạy ⇒ `UNVERIFIED (not run)`.

## Lát 1

- [ ] **Task 0 — Pre-flight + cổng dừng** · Verification: UNVERIFIED (not run) · Người dùng duyệt: ☐
- [ ] **Task 1 — Skeleton, migration `20261005210000`, models, specs db/lib** · Verification: UNVERIFIED (not run)
- [ ] **Task 2 — `Screens::Fields`** · Verification: UNVERIFIED (not run)
- [ ] **Task 3 — `RequiredSet` + helper đếm truy vấn** · Verification: UNVERIFIED (not run)
- [ ] **Task 4 — Resolver (+`matrix`, fail-open `raise_on_error`)** · Verification: UNVERIFIED (not run)
- [ ] **Task 5 — `SchemeService.assign`** · Verification: UNVERIFIED (not run)
- [ ] **Task 6 — Permission + API đọc/gán + OpenAPI** · Verification: UNVERIFIED (not run)
- [ ] **Task 7 — Project Settings UI (Layout hiệu lực, inspector)** · Verification: UNVERIFIED (not run)

## Lát 2

- [ ] **Task 8a — LayoutService, ScreenService (race test, Tầng 1.1)** · Verification: UNVERIFIED (not run)
- [ ] **Task 8b — Admin Screens UI** · Verification: UNVERIFIED (not run)
- [ ] **Task 8c — Screens API ghi, `PUT layout`, ETag/If-Match** · Verification: UNVERIFIED (not run)
- [ ] **Task 9 — Stimulus `screens--sortable`** · Verification: UNVERIFIED (not run)

## Lát 3

- [ ] **Task 10a — SchemeService đầy đủ, CoverageValidation** · Verification: UNVERIFIED (not run)
- [ ] **Task 10b — Admin Screen Schemes UI** · Verification: UNVERIFIED (not run)
- [ ] **Task 10c — Screen Schemes API (`typeItems`)** · Verification: UNVERIFIED (not run)

## Lát 4

- [ ] **Task 11 — API section/item, `for_many`, repair** · Verification: UNVERIFIED (not run)

## Việc cuối

- [ ] **Task 12 — Docs, E2E, regression, `grep jira`, copyright, redocly lint**
- [ ] Hội đồng review (security, performance, UI/UX, core integration)
- [ ] Người chạy toàn bộ suite trên máy dev; PR chuyển từ draft sang ready

## Ghi chú chênh lệch plan ↔ spec

(Ghi tại đây khi phát hiện.)
