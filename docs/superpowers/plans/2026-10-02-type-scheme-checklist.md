# Type Scheme — Task Checklist

Plan: [2026-10-02-type-scheme.md](2026-10-02-type-scheme.md) · Spec: [../specs/2026-10-02-type-scheme-design.md](../specs/2026-10-02-type-scheme-design.md) · Branch: `feature/type-schemes`

## Tasks

> Task 5–9 đã viết code + spec nhưng **chưa chạy được RSpec/rubocop** (môi trường chỉ có Ruby 3.3.6, repo cần 4.0.7, không có Postgres đang chạy). Cần chạy `bin/compose-dev rspec modules/type_schemes/spec` trước khi merge.

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
- [x] **Task 5 — Permission + Admin UI**
  - [x] Permission `assign_type_scheme`, menu Administration
  - [x] `Admin::TypeSchemesController`: index, form, clone, deactivate, delete
  - [x] Xác nhận khi gỡ Type khỏi Scheme đang dùng (số project, số WP)
  - [x] Feature spec admin + permission spec
- [x] **Task 6 — Project Settings UI**
  - [x] Chọn Scheme cho project, hiển thị Available Types, cảnh báo thiếu Type
- [x] **Task 7 — API v3**
  - [x] `/api/v3/type_schemes` (CRUD), `PUT projects/:id/type_scheme`, `GET projects/:id/available_types`
  - [x] Tài liệu OpenAPI trong `docs/api/apiv3`
- [x] **Task 8 — Default Scheme + migration dữ liệu**
  - [x] Listener `PROJECT_CREATED` tự gán Default Scheme
  - [x] Rake `type_schemes:migrate[dry_run|auto|manual]`
  - [x] Test gỡ module không mất `types`/`work_packages`
- [x] **Task 9 — E2E, regression, tài liệu**
  - [x] E2E tạo WP với Scheme (UI + API)
  - [x] Regression core, lint, i18n spec
  - [x] Tài liệu admin

- [x] **Task 10 — Scheme bắt buộc, Default Scheme default = Task** (spec §13.1)
  - [x] `DefaultScheme` (ensure!/current/add_type), Resolver fallback, bỏ unassign, API/UI không cho rỗng
  - [x] Listener project mới, migration dữ liệu, hook Type mới, bất biến Default Scheme
- [x] **Task 11 — Không cho xoá Scheme** (spec §13.2)
  - [x] Bỏ destroy ở service/controller/route/UI/API/OpenAPI/docs/specs, model chặn destroy
- [x] **Task 12 — Kéo-thả sắp xếp Type** (spec §13.3)
  - [x] Stimulus controller + view + i18n + spec

## Việc cuối

- [ ] Final whole-branch review (cần chạy RSpec thật — chưa chạy được trong môi trường Ruby 3.3.6)
- [ ] `finishing-a-development-branch`

## Ghi chú cho các task còn lại (từ review các task trước)

- `SchemeService` nhận hash khoá **symbol**; không gọi trong transaction ngoài (chưa dùng `requires_new`); sau `update` thất bại phải reload scheme.
- Có 2 prepend vào core (không sửa file core): `BaseContract` và `SetAttributesService`.
- Test chạy qua `bin/compose-dev rspec ...` (Docker). Không commit `bin/compose-dev`, `docker-compose.dev.yml`, các script `docker/dev/backend/scripts/*` và `bin/*` đã đổi CRLF→LF.
