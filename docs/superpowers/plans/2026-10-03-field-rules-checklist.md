# Field Rules — Task Checklist

Spec: [2026-10-03-field-rules-design.md](../specs/2026-10-03-field-rules-design.md) · Idea: [idea-02](../../ideas/idea-02.md) · Branch: `feature/type-schemes`

> Môi trường chỉ có Ruby 3.3.6 (repo cần 4.0.7), không Postgres/Docker/node_modules: code và spec chưa chạy được. Chạy `bin/compose-dev rspec modules/field_rules/spec` trên máy dev.

- [x] **Task 1 — Module, migration, models, registry field, ma trận hợp lệ**
- [x] **Task 2 — Resolver (layer native ⊕ rule), cache, Validator**
- [x] **Task 3 — Enforcement: writable_attributes, required (grandfather), default khi tạo, add_constraint chain, schema to_json, boot guard**
- [x] **Task 4 — Services (rule set, scheme: create/update/clone/activate/deactivate/assign/impact)**
- [x] **Task 5 — Permission + Admin UI + Project settings**
- [x] **Task 6 — API v3 + OpenAPI**
- [x] **Task 7 — Docs, repair task, E2E, hội đồng review**

## Việc cuối

- [ ] Hội đồng review (security, performance, UI/UX, safety, core integration)
- [ ] Chạy toàn bộ spec trên máy dev
