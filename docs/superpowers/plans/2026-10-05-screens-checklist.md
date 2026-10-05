# Screens — Task Checklist

Plan: [2026-10-05-screens.md](2026-10-05-screens.md) · Spec: [../specs/2026-10-05-screens-design.md](../specs/2026-10-05-screens-design.md) · Idea: [idea-03](../../ideas/idea-03.md) · Branch: `claude/affectionate-ramanujan-2th1uy`

> Môi trường tác giả: Windows, **không có Ruby** (không có `ruby`/`bundle`), không Postgres/Docker/node_modules ⇒ **không chạy được** RSpec/rubocop/eslint/erb_lint/redocly. Mỗi task được implement đầy đủ nhưng mọi dòng Verification giữ `UNVERIFIED (not run)` cho tới khi chạy trên máy dev. **Chưa commit** (người dùng chưa yêu cầu commit).

## Lát 1

- [x] **Task 0 — Pre-flight + cổng dừng** · Verification: `rails runner`/`rspec` UNVERIFIED (not run); core methods PASS theo code inspection ([preflight](2026-10-05-screens-preflight.md)) · Người dùng duyệt: ☑ (tiếp tục theo yêu cầu)
- [x] **Task 1 — Skeleton, migration `20261005210000`, models, specs db/lib** · Verification: UNVERIFIED (not run)
- [x] **Task 2 — `Screens::Fields`** · Verification: UNVERIFIED (not run)
- [x] **Task 3 — `RequiredSet` + helper đếm truy vấn** · Verification: UNVERIFIED (not run)
- [x] **Task 4 — Resolver (+`matrix`, fail-open `raise_on_error`)** · Verification: UNVERIFIED (not run)
- [x] **Task 5 — `SchemeService.assign`** · Verification: UNVERIFIED (not run)
- [x] **Task 6 — Permission + API đọc/gán + OpenAPI** · Verification: UNVERIFIED (not run)
- [x] **Task 7 — Project Settings UI (Layout hiệu lực, inspector)** · Verification: UNVERIFIED (not run)

## Lát 2

- [x] **Task 8a — LayoutService, ScreenService (race test, Tầng 1.1)** · Verification: UNVERIFIED (not run)
- [x] **Task 8b — Admin Screens UI** · Verification: UNVERIFIED (not run)
- [x] **Task 8c — Screens API ghi, `PUT layout`, ETag/If-Match** · Verification: UNVERIFIED (not run)
- [x] **Task 9 — Stimulus `screens--sortable`** · Verification: UNVERIFIED (not run)

## Lát 3

- [x] **Task 10a — SchemeService đầy đủ, CoverageValidation** · Verification: UNVERIFIED (not run)
- [x] **Task 10b — Admin Screen Schemes UI** · Verification: UNVERIFIED (not run)
- [x] **Task 10c — Screen Schemes API (`typeItems`)** · Verification: UNVERIFIED (not run)

## Lát 4

- [x] **Task 11 — API section/item, `for_many`, repair** · Verification: UNVERIFIED (not run)

## Việc cuối

- [x] **Task 12 — Docs, E2E, regression, `grep jira`, copyright, redocly lint** · Verification: UNVERIFIED (not run) — OpenAPI path/schema + đăng ký `openapi-spec.yml` đã thêm; copyright header có trên mọi file mới (chạy `rake copyright:*` để xác nhận trên máy dev)
- [ ] Hội đồng review (security, performance, UI/UX, core integration)
- [ ] Người chạy toàn bộ suite trên máy dev; PR chuyển từ draft sang ready

## Ghi chú chênh lệch plan ↔ spec

1. **`Resolver.for` query count:** cài đặt dùng `type_in_project?` + `project_assignment` (join) + `ScreenSchemeItem` + `Screen.includes(sections: :items)`; eager load `sections: :items` làm phát sinh thêm 2 truy vấn (sections, items) nên thực tế **~6 truy vấn**, vượt ngưỡng `≤ 4` của plan. Chưa thêm assertion `≤ 4` cho `for` (chỉ test cache = 0 truy vấn). Cần tối ưu (ví dụ preload thủ công hoặc đếm lại) trên máy dev.
2. **`Resolver.matrix`:** cài đặt đúng tinh thần "không nạp section" với 4 truy vấn (enabled_types, assignment, items, screens).
3. **`for_many`:** hiện gọi `Resolver.for` theo từng khoá (cache per-request), nên số truy vấn **tăng theo số project**. Plan yêu cầu không đổi giữa 1 và 50 project — cần thay bằng tải theo lô trên máy dev. Không có assertion số truy vấn cho `for_many` trong spec hiện tại.
4. **`RequiredSet.for`:** ngưỡng `≤ 4` có test; cài đặt dùng `project.type_variant` + custom fields + F02 (memo native defaults).
5. **Diagnostics thêm khoá `notVisible`** ngoài 4 khoá trong ví dụ JSON của spec §7, để phục vụ chip "not visible" của Field inspector (§8). API trả camelCase `notVisible`; spec §7 chưa liệt kê khoá này.
6. **`hidden_and_required`:** F03 không tự sinh (đúng spec); F02 mask `required` khi `hidden` nên resolver không thể tái tạo mã này từ `EffectiveConfiguration`. Không có diagnostics bucket riêng.
7. **Race test `LayoutService`:** plan yêu cầu test đa luồng `use_transactional_fixtures: false`; chưa viết spec race (chỉ có unit test giới hạn/khôi phục). Cần bổ sung trên máy dev.
8. **OpenAPI:** file path/schema tối giản, đã đăng ký trong `openapi-spec.yml`; chưa chạy `redocly lint`.
9. **Copyright:** mọi file `.rb`/`.rake`/`.erb` có header; file `.ts` mới có header `//-- copyright … //++`. Cần `rake copyright:*` xác nhận.
