# Field Rules — Design Spec (Feature 02)

Nguồn: [docs/ideas/idea-02.md](../../ideas/idea-02.md) (đã review-revise, §0) · Ngày: 2026-10-03 · Phụ thuộc: Feature 01 (`modules/type_schemes`)

Quyết định đã chốt với người dùng: (1) bỏ drag & drop; (2) required khi sửa work package cũ dùng grandfather, có tuỳ chọn `enforce_on_update` theo rule; (3) field của module khác chỉ cấu hình được qua allowlist do module đăng ký.

## 1. Mục tiêu và phạm vi

Với một Project + Type: field nào bị **ẩn**, **bắt buộc**, **chỉ đọc**, có **giá trị mặc định**. Plugin chỉ lưu *rule*, không lưu dữ liệu field, không tạo Custom Field.

In (V1): Field Rule Set + Rule, Field Rule Scheme (type → rule set) gán cho project, resolver hợp nhất với cấu hình native, enforce server-side (contract, API schema, default khi tạo), admin UI, project settings, API v3, permission, migration, test.
Out: kéo-thả (bỏ hẳn), inheritance, Bulk Edit UI, giải xung đột Workflow, thứ tự/layout form (Feature 03), cấu hình field ngoài allowlist.

## 2. Đối chiếu code (đã kiểm chứng)

| Chủ đề | Thực trạng | Hệ quả |
|---|---|---|
| Hidden native | Field không nằm group nào của `FormConfiguration` thì không hiện. Extension point `TypeVariant.add_constraint(attr, callable)`; **một attribute một callable** (Backlogs/Costs/Budgets/ResourceManagement đã dùng) | Hidden = chặn ghi + loại khỏi schema; không thể ép hiện field. Constraint phải bọc chuỗi. |
| Required | Chỉ custom field qua `required_attributes` của variant → `WorkPackage#custom_field_required?` | Required cho native field là khoảng trống; enforce ở contract. |
| Read-only / writable | `BaseContract#writable_attributes` (kèm custom field); schema `writable` suy ra từ đó; ghi attribute không writable ⇒ `error_readonly` | Hook sạch cho read-only và hidden: prepend `writable_attributes` (đã prepend `BaseContract` ở F01). |
| Schema `required` | Native: hằng số khai báo lúc load class; chỉ custom field động. JSON schema được cache theo (project, type, type_variant) rồi `to_json` ghép phần uncacheable | Sửa JSON **sau cache** bằng prepend `to_json` của `WorkPackageSchemaRepresenter`, không đụng cache key. |
| Default | Chỉ `default_work_package_description` + subject pattern của variant; custom field `default_value` | Default của rule áp trong `SetAttributesService` (đã prepend ở F01), chỉ khi tạo. |
| Tên | Core có `FormConfiguration*` | Dùng `FieldRule*`. |

## 3. Data model

```text
field_rule_sets        id, name (unique, ≤255), description (≤5000), active, timestamps
field_rules            id, rule_set_id FK cascade, field_key, hidden bool, required bool,
                       read_only bool, enforce_on_update bool default false,
                       default_value text null, position int, timestamps
                       UNIQUE(rule_set_id, field_key)
field_rule_schemes     id, name (unique, ≤255), description, active, timestamps
field_rule_scheme_items id, scheme_id FK cascade, type_id FK cascade, rule_set_id FK,
                       UNIQUE(scheme_id, type_id)
project_field_rule_schemes id, project_id FK cascade UNIQUE, scheme_id FK
```

`field_key` được validate bằng allowlist (§5), không FK. `visibility` của idea được biểu diễn bằng cờ `hidden` (mặc định visible). Không xoá Rule Set/Scheme (deactivate/activate/clone), xoá *rule* trong rule set được phép. `before_destroy` chặn xoá ở model; FK `rule_set_id`/`scheme_id` không cascade.

## 4. Ma trận hợp lệ của một rule (validate khi lưu)

* `hidden` + `required` ⇒ lỗi `hidden_and_required`.
* `required` + `read_only` mà không có `default_value` ⇒ lỗi `read_only_required_without_default`.
* `hidden` + `read_only` ⇒ chuẩn hoá `read_only = false` (hidden đã chặn ghi).
* `default_value` được kiểm tra theo kiểu field (id tồn tại, ngày ISO8601, số, CF qua `custom_field.cast_value`); sai ⇒ `invalid_default`.
* Field không trong allowlist hoặc custom field không phải WorkPackageCustomField ⇒ `unknown_field`.

## 5. Allowlist field

`FieldRules::Fields` là registry: key → `{ writable_attributes:, schema_keys:, kind: }`.

| key | contract attributes | schema key | default_value |
|---|---|---|---|
| `description` | `description` | `description` | text |
| `assignee` | `assigned_to_id` | `assignee` | user id |
| `responsible` | `responsible_id` | `responsible` | user id |
| `priority` | `priority_id` | `priority` | priority id |
| `category` | `category_id` | `category` | category id |
| `target_versions` | `target_versions` | `targetVersions` | không hỗ trợ default |
| `start_date` / `due_date` | cùng tên | `startDate` / `dueDate` | ISO8601 |
| `estimated_time` | `estimated_hours` | `estimatedTime` | giờ (số) |
| `custom_field_<id>` | `custom_field_<id>` | `customField<id>` | `cast_value` |

Không cấu hình được: `subject`, `type`, `project`, `status`, `author`, mọi field tự sinh/derived, `parent`. Module khác đăng ký thêm qua `FieldRules::Fields.register(key, **definition)` (V1 không tự đăng ký Backlogs/Costs; cơ chế sẵn sàng).

## 6. Resolver (hiệu lực)

`FieldRules::Resolver.for(project, type)` → `EffectiveConfiguration` (immutable, theo key):

```text
Layer 0 native : field có trong form (constraint) / required custom field (variant+global) / status read-only
Layer 1 rules  : rule set của (Field Rule Scheme của project, type)
hidden   = rule.hidden
required = native_required OR (rule.required AND not hidden)
read_only= native_read_only OR rule.read_only
default  = rule.default_value (nil nếu không có)
source   = :native | :rule_set (để UI hiển thị nguồn)
```

Không có scheme / scheme inactive / không có item cho type / rule set inactive ⇒ cấu hình rỗng (hành vi native). Cache theo (project_id, type_id) trong `RequestStore`, reset khi model đổi (giống Feature 01); `for_many` preload một lần. `editable?(project, type, field)` cho Bulk Edit sau này; `conflicts_with(requirements)` cho Workflow sau này.

## 7. Enforcement

Tác nhân: `actor = :user` khi `User.current` không phải `User.system` và contract không có cờ `system_update`; cập nhật phát sinh từ scheduling/ancestors (user hệ thống) ⇒ `:system` ⇒ không áp rule. Mọi lỗi trong resolver ⇒ fail-open (log, cấu hình rỗng).

1. **Hidden & read-only (ghi):** prepend `BaseContract#writable_attributes` loại các contract attribute của field hidden/read_only (đối với `actor = :user`). Ghi vào chúng ⇒ `error_readonly` của contract hiện có. Với **create**, field read_only/hidden có default vẫn được hệ thống điền (bước 3), không phải người dùng ghi.
2. **Required (server-side):** validation thêm vào `BaseContract` (prepend): với field required và rỗng: lỗi `blank` kèm thông điệp i18n "%{attribute} is required for %{type}". Áp dụng:
   * Create: luôn.
   * Update: chỉ khi (a) field đang thay đổi/bị xoá, hoặc (b) `type`/`project` thay đổi, hoặc (c) rule có `enforce_on_update`. Ngoài ra không báo lỗi (grandfather).
3. **Default khi tạo:** prepend `SetAttributesService` (đã có) thêm bước `apply_field_rule_defaults`: chỉ work package mới, chỉ field chưa có giá trị do người dùng cung cấp, sau khi đã biết type và project; thứ tự ưu tiên: giá trị người dùng > default của rule > native default (không ghi đè nếu native đã gán giá trị khác mặc định rỗng).
4. **Hidden (hiển thị):** `TypeVariant.add_constraint(attr, wrapper)` bọc constraint cũ (nếu có) với `old.nil? || old.call(...)` AND `!hidden(project, type)`; áp dụng cho field native thuộc allowlist có constraint-compatible. Với custom field hidden, loại khỏi `available_custom_fields` của form không thể qua constraint ⇒ dùng schema patch.
5. **Schema API (sau cache):** prepend `WorkPackageSchemaRepresenter#to_json`: nếu có rule cho (project, type): với field hidden xoá khỏi JSON và khỏi `_attributeGroups[*].attributes`; với required đặt `required: true`; với read_only đặt `writable: false`. Không có rule ⇒ trả nguyên chuỗi, không parse lại.
6. **Boot guard:** `assert_patch_targets!` kiểm tra `writable_attributes`, `to_json`, `assign_default_type`/bước default tồn tại; thiếu ⇒ raise lúc boot (như F01).

## 8. Permission, UI, API

* `manage_field_rules` (admin-only, menu `Administration → Work packages → Field rules`); `assign_field_rule_scheme` (project permission, `require: :member`, Project Settings → "Field rule scheme"); xem rule hiệu lực: member có `view_work_packages`.
* Admin UI (không kéo-thả): danh sách Rule Set (Name, số Type dùng, số project, Status; Edit/Clone/Deactivate/Activate), form Rule Set = bảng field (Hidden / Required / Read-only / Enforce on update / Default) với nhãn nguồn (native vs rule) và cảnh báo field không active trong project; danh sách Scheme và form map Type → Rule Set; trang xác nhận khi sửa rule set/scheme đang dùng (số project, số work package). A11y: nhãn đầy đủ, `caption`, bảng responsive. Chuỗi qua i18n.
* API v3 (HAL): `GET /api/v3/projects/{id}/types/{type_id}/field_rules` (cấu hình hiệu lực kèm `source`), CRUD `/api/v3/field_rule_sets` và `/api/v3/field_rule_schemes` (ghi: admin; không có DELETE), `PUT /api/v3/projects/{id}/field_rule_scheme`. OpenAPI trong `docs/api/apiv3`.

## 9. Bảo mật, hiệu năng, an toàn

* Authz server-side mọi action; strong params; giới hạn kích thước (name 255, description 5000, tối đa 100 rule/set, 200 item/scheme); input sai kiểu ⇒ 4xx không 500; không `html_safe`; transaction + lock khi sửa; RecordNotUnique ⇒ lỗi validation.
* Cache resolver theo request + `for_many`; không query rule trong vòng lặp work package; index trên `(scheme_id,type_id)`, `project_id`, `(rule_set_id, field_key)`; schema patch bỏ qua khi không có rule.
* Fail-open; rake `field_rules:repair`; migration không động tới bảng core; gỡ module chỉ bỏ 5 bảng.

## 10. Rủi ro

Schema `to_json` patch phụ thuộc cấu trúc JSON của core (boot guard + spec); constraint chain với module khác; nới lỏng required native không được phép; hiệu ứng lên import/mail handler (actor user + grandfather). Các điểm còn lại theo idea §0.3.

## 11. Acceptance

Theo idea-02 §26 (đã revise) và §7 ở trên.
