# Screens — Pre-flight

Plan: [2026-10-05-screens.md](2026-10-05-screens.md) · Ngày: 2026-10-05 · Branch: `claude/affectionate-ramanujan-2th1uy`

> Môi trường agent: Windows, **không có Ruby** (`ruby` không có trong PATH), không Postgres, không `node_modules`. Do đó các step cần `rails runner`/`rspec`/`psql` được ghi `UNVERIFIED (not run)`; các step kiểm chứng được bằng đọc code/grep được ghi rõ nguồn.

## Step 1 — Extras field

Lệnh không chạy được (`rails runner` không có Ruby). Kiểm chứng bằng đọc code:

- `app/models/type/attributes.rb:138` `skipped_attribute?` loại mọi key có `definition[:required]` (trừ `priority`) và mọi key trong `EXCLUDED`. `EXCLUDED` (`:34`) chứa `description`.
- `subject`, `status` có `required: true` trong schema representer ⇒ **không** xuất hiện trong `all_work_package_form_attributes`.
- `description` nằm trong `EXCLUDED` ⇒ cũng không xuất hiện.

**Kết luận:** extras `%w[subject description status]` là cần thiết (§5 giữ nguyên). Status: UNVERIFIED (not run) cho `rails runner`; PASS theo code inspection.

## Step 2 — Sự kiện xoá custom field

`grep -rn "after_destroy|Notifications|notify" app/models/custom_field.rb lib/open_project/notifications*`:

- `app/models/custom_field.rb:99` chỉ có `after_destroy :destroy_help_text`; **không** phát `OpenProject::Notifications` khi destroy.
- Không có hook sạch để dọn item mồ côi mà không patch core.

**Kết luận:** dùng `screens:repair` + resolver bỏ qua item mồ côi (đúng §2/§3 spec). PASS theo code inspection.

## Step 3 — Core dependency signatures

| Phương thức | Nguồn | Trạng thái |
|---|---|---|
| `Project#type_variant(type)` | `app/models/projects/enabled_types.rb:46` | PASS |
| `Project#type_variants(*types)` | `app/models/projects/enabled_types.rb:58` | PASS |
| `TypeVariant#required_attributes` | `app/models/type_variants/form_reference.rb:69` | PASS |
| `TypeVariant#passes_attribute_constraint?(attribute, project: nil)` | `app/models/type/attributes.rb:196` | PASS |
| `TypeVariant.all_work_package_form_attributes` | `app/models/type/attributes.rb:81` | PASS |
| `TypeVariant.translated_work_package_form_attributes` | `app/models/type/attributes.rb:94` | PASS |
| `TypeVariant include ::Type::Attributes` | `app/models/type_variant.rb:50` | PASS |

Lưu ý quan trọng: `Project#type_variant` trả `type.default_variant` khi type **không** được bật ở project ⇒ Resolver phải kiểm tra `ProjectType` (`project.project_types`/`ProjectType.exists?`) để phát hiện `type_not_in_project`, không dựa vào `type_variant` trả `nil`.

## Step 4 — Baseline

`bundle exec rspec modules/field_rules/spec modules/type_schemes/spec`: UNVERIFIED (not run) — không có Ruby.

## Step 5 — Hook + mã migration

- `bundle exec lefthook install`: UNVERIFIED (not run).
- `20261005210000` chưa được dùng (đã kiểm: chỉ `modules/type_schemes/.../20261005200000_add_color_to_type_scheme_items.rb` tồn tại). PASS.

## Step 6 — Cổng dừng

- (a) Không thiếu phương thức core (Step 3 PASS).
- (b) Baseline chưa chạy được (UNVERIFIED) — không kết luận đỏ.
- (c) Composite FK migrate được theo cú pháp `add_foreign_key ... primary_key: %i[id screen_id]` (tiền lệ trong repo dùng `check_constraint`; `schema_format :sql`).

Người dùng đã yêu cầu triển khai plan này; agent tiếp tục Task 1 với ghi chú rằng mọi bằng chứng runtime cần chạy trên máy dev.
