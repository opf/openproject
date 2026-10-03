# Type Scheme — Task Checklist

Plan: [2026-10-02-type-scheme.md](2026-10-02-type-scheme.md) · Spec: [../specs/2026-10-02-type-scheme-design.md](../specs/2026-10-02-type-scheme-design.md) · Branch: `feature/type-schemes`

## Tasks

- [x] **Task 1 — Module skeleton, migration, models** (`bd4014d`, fix `95f0021`)
  - [x] Module `modules/type_schemes`, đăng ký trong `Gemfile.modules`
  - [x] Migration 3 bảng `type_schemes`, `type_scheme_items`, `project_type_schemes`
  - [x] Models `TypeScheme`, `TypeSchemeItem`, `ProjectTypeScheme` + factory + spec
- [x] **Task 2 — Resolver** (`1d9df41`, fix `139531b`)
  - [x] `Resolver.for_project`, `Resolver.allowed_types` (default trước, rồi theo position)
- [x] **Task 3 — Hook vào core (2 prepend trong module)** (`947eafb`, fix `74b6bb1`)
  - [x] `WorkPackages::BaseContract#assignable_types` + validate `:not_in_scheme`
  - [x] `WorkPackages::SetAttributesService#assign_default_type` (default type theo Scheme)
  - [x] Request spec API v3 form; spike Angular ghi trong spec §10
- [x] **Task 4 — `SchemeService`** (`8697d80`)
  - [x] create / update / clone / deactivate / destroy / assign / unassign / impact
- [ ] **Task 5 — Permission + Admin UI**
  - [ ] Permission `assign_type_scheme`, menu Administration
  - [ ] `Admin::TypeSchemesController`: index, form, clone, deactivate, delete
  - [ ] Xác nhận khi gỡ Type khỏi Scheme đang dùng (số project, số WP)
  - [ ] Feature spec admin + permission spec
- [ ] **Task 6 — Project Settings UI**
  - [ ] Chọn Scheme cho project, hiển thị Available Types, cảnh báo thiếu Type
- [ ] **Task 7 — API v3**
  - [ ] `/api/v3/type_schemes` (CRUD), `PUT projects/:id/type_scheme`, `GET projects/:id/available_types`
  - [ ] Tài liệu OpenAPI trong `docs/api/apiv3`
- [ ] **Task 8 — Default Scheme + migration dữ liệu**
  - [ ] Listener `PROJECT_CREATED` tự gán Default Scheme
  - [ ] Rake `type_schemes:migrate[dry_run|auto|manual]`
  - [ ] Test gỡ module không mất `types`/`work_packages`
- [ ] **Task 9 — E2E, regression, tài liệu**
  - [ ] E2E tạo WP với Scheme (UI + API)
  - [ ] Regression core, lint, i18n spec
  - [ ] Tài liệu admin

## Việc cuối

- [ ] Final whole-branch review
- [ ] `finishing-a-development-branch`

## Ghi chú cho các task còn lại (từ review các task trước)

- `SchemeService` nhận hash khoá **symbol**; không gọi trong transaction ngoài (chưa dùng `requires_new`); sau `update` thất bại phải reload scheme.
- Có 2 prepend vào core (không sửa file core): `BaseContract` và `SetAttributesService`.
- Test chạy qua `bin/compose-dev rspec ...` (Docker). Không commit `bin/compose-dev`, `docker-compose.dev.yml`, các script `docker/dev/backend/scripts/*` và `bin/*` đã đổi CRLF→LF.
