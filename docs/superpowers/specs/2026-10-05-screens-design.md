# Screens — Design Spec (Feature 03)

Nguồn: [docs/ideas/idea-03.md](../../ideas/idea-03.md) · Ngày: 2026-10-05 (revise sau review hội đồng, cùng ngày) · Phụ thuộc: chỉ **đọc** `ProjectType`/`TypeVariant` của core (Feature 01 không phải điều kiện cứng, không khai báo `depends_on`); Feature 02 (`modules/field_rules`) là **phụ thuộc mềm**.

## 0. Review & Revision (hội đồng 5 góc nhìn)

Bản đầu được review song song bởi 5 reviewer: (A) độ chính xác so với code, (B) mô hình dữ liệu/toàn vẹn, (C) API & resolver, (D) sản phẩm/UX/trợ năng, (E) bảo mật/hiệu năng/kiểm thử. Các mục dưới đây là thay đổi so với bản đầu; phần còn lại của tài liệu đã được viết lại theo đó.

### 0.1 Sai lệch so với code đã kiểm chứng

| # | Bản đầu nói | Code thực tế | Sửa |
|---|---|---|---|
| A1 | Registry = `all_work_package_form_attributes.keys` + `description`. | `skipped_attribute?` (`app/models/type/attributes.rb`) loại mọi key có `required: true` (trừ `priority`) ngoài `EXCLUDED`. `schema :subject` không khai `required:` nên `subject` (và các key tương tự như `status`) **không có** trong form attributes. | Extras tường minh `subject`, `description`, `status` (§5); test khẳng định `subject` placeable; kiểm chứng bằng `rails runner` trước khi code. |
| A2 | Required custom field = `custom_field_required?`. | Đó là method của `WorkPackage` (cần instance). Phía variant: `TypeVariant#required_attributes` (gồm cả key native lẫn `custom_field_<id>`, giao với group members). | Tập bắt buộc viết lại ở §4. |
| A3 | "Không có helper tìm variant". | Có `Project#type_variant(type)` và `Project#type_variants(*types)` (`app/models/projects/enabled_types.rb`). | Dùng helper; ghi vào boot guard. |
| A4 | Route `confirm` riêng. | F02 không có route `confirm`; `update` render lại view `confirm` với 422 cho đến khi `confirm=1`. | Theo F02 (§8). |
| A5 | `acts_as_list` "như F01/F02". | F01/F02 dùng cột `position` thường. `acts_as_list` có ở core (`FormConfigurationGroup`). | Dùng cột `position` thường + service chuẩn hoá (§3). |
| A6 | Reuse `type-schemes--sortable-types`, "không sửa core". | Controller nằm ở **core frontend** (`frontend/src/stimulus/controllers/dynamic/type-schemes/`), đăng ký ở `frontend/src/stimulus/setup.ts`. | Controller mới `screens--sortable` cũng ở core frontend; nêu rõ trong §8 (không sửa Ruby core/bảng core, có thêm file frontend, kèm copyright header). |
| A7 | Permission đơn lẻ; mount API chung chung. | Engine bọc permission trong `project_module nil`; mount ở `API::V3::Root` và `API::V3::Projects::ProjectsAPI, :id`. | Ghi rõ §7/§8. |
| A8 | `passes_attribute_constraint?` dùng được với variant. | Instance method của `TypeVariant`; `project: nil` ⇒ bỏ qua kiểm tra custom field. | Luôn truyền `project:`; `available?` fail-open khi variant nil. |
| A9 | OpenAPI "components". | `docs/api/apiv3/components/schemas/*_model.yml` và `*_collection_model.yml`. | Sửa §7. |

### 0.2 Thay đổi thiết kế

1. **`required_not_placed` không còn là validation chặn tuỳ ý (reviewer B, D, E).** Bản đầu chặn lưu Screen dựa trên trạng thái F02 của mọi project dùng scheme ⇒ vòng phụ thuộc với F02 (F02 không biết F03), lỗi do người khác gây ra, chi phí O(projects × types) trong transaction. Cách mới có hai tầng (§4): **Tầng 1 (chặn)** chỉ những thứ chứng minh được và rẻ; **Tầng 2 (cảnh báo/diagnostics)** mọi thứ phụ thuộc F02/project. Đây là **thu hẹp Q-C so với idea** — cần chủ sản phẩm xác nhận (§13).
2. **`hidden_and_required` giữ trong danh sách mã ổn định (reviewer D)** như mã kế thừa từ F02; F03 không tự sinh mà thể hiện qua `requiredNotPlaced`.
3. **Fallback context xác định hoàn toàn (reviewer C):** bảng `FALLBACKS`, `reason` luôn có khi `native`, `diagnostics.skipped`.
4. **Type không bật trong project ⇒ 404** ở API (không trả native), không rò layout/diagnostics (reviewer C, E).
5. **API nhất quán với F02/API v3 (reviewer C):** `PATCH {active}` thay `POST activate/deactivate`; `typeItems` với `_links`; bảng ánh xạ mã lỗi → định danh lỗi API v3; payload resolver có `label`, `reason`, `stateSource`, link schema; thêm `PUT /screens/{id}/layout` (lưu cả layout trong một transaction) và `GET /projects/{id}/screen_scheme`.
6. **Toàn vẹn ở DB (reviewer B):** FK phức hợp `(section_id, screen_id)`, CHECK, `screen_type` bất biến tuyệt đối, khoá `with_lock` cho mọi thay đổi layout, unique tên section không phân biệt hoa thường.
7. **Bảo mật/DoS (reviewer E):** giới hạn đầu vào có mã lỗi, tra cứu lồng nhau theo cha, `diagnostics` chỉ cho người có quyền, báo lỗi fail-open qua `Rails.error.report`.
8. **UX cụ thể hoá (reviewer D):** bảng "Layout hiệu lực" Type × context, field inspector, banner, clone = bản sao riêng, xác nhận một lần mỗi lần lưu layout, a11y.
9. **Cắt lát lại (reviewer D):** chưa có bên tiêu thụ API ⇒ ưu tiên resolver + xem trước trước, CRUD chi tiết của section/item và `for_many` sau (§12).

### 0.3 Điểm các reviewer bất đồng và cách chọn

* Phạm vi kiểm tra `required_not_placed`: reviewer B muốn bỏ hẳn tầng F02 khỏi validation; reviewer D muốn giữ đúng Q-C của idea (kể cả F02, trên mọi project). **Chọn trung gian:** chặn ở `ScreenSchemeItem` (chỉ type của dòng đang lưu, có chặn trên về số project), không bao giờ chặn khi lưu `Screen` vì lý do phụ thuộc F02/project (§4).
* Context sai: reviewer C đề xuất 404/400 theo thói quen API v3; idea (kịch bản 7) ghi 422 `invalid_context`. **Giữ 422** theo idea; ghi trong §13.

## 1. Mục tiêu và phạm vi

Với một Project + Type + ngữ cảnh (`create`, `edit`, `view`, `transition`): **field nào nằm ở section nào, theo thứ tự nào**. Plugin chỉ lưu *layout*; không lưu dữ liệu field, không có model Field, không đổi required/hidden/read-only/default (thuộc F02). Screen **không phải ranh giới enforcement**: API/import vẫn tạo/sửa work package bất kể screen.

In (V1): Screen / Section / Item, Screen Scheme (Type → screen theo ngữ cảnh), gán cho project, Resolver hợp nhất với trạng thái F02, kiểm tra xung đột, admin UI (kéo-thả), project settings (xem layout hiệu lực), API v3, permission, migration, test, OpenAPI.

Out: workflow/transition logic (chỉ có slot + context), automation, hành vi field động, ghi vào `FormConfiguration` native, sửa Angular native, block không phải field (Feature 04), kế thừa, import/export screen.

## 2. Đối chiếu code (đã kiểm chứng)

| Chủ đề | Thực trạng | Hệ quả |
|---|---|---|
| Layout native | `ProjectType` gắn `variant`; variant gắn `FormConfiguration` (group `attribute`/`query`); schema API v3 đưa ra `_attributeGroups`. Tạo/sửa/xem dùng cùng layout. | Native là mặc định (`source: native`); F03 không đọc/ghi `FormConfiguration` (Q-D). |
| Field đặt được | Xem A1 ở §0.1 và §5. | Registry có extras. |
| Tìm variant | `project.type_variant(type)`, `project.type_variants(*types)`. | Dùng helper. |
| Khả dụng | `variant.passes_attribute_constraint?(key, project:)`; `custom_field_in_project?` (cache `RequestStore`). | Luôn truyền `project:`. |
| F02 | `FieldRules::Resolver.for(project, type)` (positional), `for_many(project_ids, type_ids)`, `reset_cache`; `EffectiveConfiguration#hidden?/required?/read_only?/fields[key].default_value`. Chỉ đăng ký 9 field native + custom field; `EffectiveField#source` luôn `:rule_set`. `required`/`read_only` đã bị mask bởi `hidden`. | Gắn `state` khi F02 có; `defined?(FieldRules::Resolver)` là kiểm tra lúc load (F02 "tắt" = gem không có trong `Gemfile.modules`, không phải cờ runtime). |
| Quy ước module | `ActsAsOpEngine`, `register … bundled: true`; menu `:admin_menu` parent `:admin_work_packages`; `project_module nil do permission … permissible_on: :project, require: :member end`; mount `API::V3::Root` + `API::V3::Projects::ProjectsAPI, :id`; `Gemfile.modules`; routes `except: %i[show destroy]` + member `clone/activate/deactivate`. | Sao chép `modules/field_rules`. |
| Boot guard | F02 patch core nên có `assert_patch_targets!`. F03 không patch, nhưng phụ thuộc: `TypeVariant.all_work_package_form_attributes`, `TypeVariant.translated_work_package_form_attributes`, `TypeVariant#passes_attribute_constraint?`, `Project#type_variant`. | `assert_core_dependencies!` raise lúc boot nếu thiếu. |

Cần xác minh khi implement: (a) `subject`/`status` thật sự vắng trong `all_work_package_form_attributes` (`rails runner`); (b) cách hệ thống phát sự kiện khi xoá custom field để dọn item mồ côi mà không patch core (nếu không có, dùng `screens:repair` + resolver bỏ qua).

## 3. Data model

```text
screens                id, name (unique, ≤255), description text (≤5000),
                       screen_type string NOT NULL no default,
                       active default true, timestamps
                       CHECK screen_type IN ('create','edit','view','transition')
screen_sections        id, screen_id FK cascade, name (≤255), position int NOT NULL default 0,
                       timestamps
                       UNIQUE(id, screen_id)            -- đích của FK phức hợp
                       UNIQUE(screen_id, lower(name))
screen_items           id, screen_id, section_id, field_key, position int NOT NULL default 0,
                       width string NOT NULL default 'full', visible bool NOT NULL default true,
                       timestamps
                       FK (section_id, screen_id) -> screen_sections(id, screen_id) ON DELETE CASCADE
                       UNIQUE(screen_id, field_key)   INDEX(section_id, position)
                       CHECK width IN ('full','half')
screen_schemes         id, name (unique, ≤255), description text, active default true, timestamps
screen_scheme_items    id, scheme_id FK cascade (index: false), type_id FK types cascade,
                       create_screen_id, edit_screen_id, view_screen_id, transition_screen_id
                       (mỗi cột FK screens, nullable, ON DELETE RESTRICT, có index), timestamps
                       UNIQUE(scheme_id, type_id)
project_screen_schemes id, project_id FK cascade UNIQUE, scheme_id FK (RESTRICT, có index), timestamps
```

* **Không** UNIQUE trên `position` (tránh lỗi giữa chừng khi dịch chuyển). `position` là cột thường; validate số nguyên `0..99_999` như F01/F02; service chuẩn hoá về `1..n` liên tục sau mỗi thay đổi.
* Đặt tên khớp F02 (`scheme_id`, `type_id`); ánh xạ với idea ở §7.1.
* Giới hạn (hằng trên model: `Screen::MAX_SECTIONS`, `Screen::MAX_ITEMS`, `ScreenScheme::MAX_ROWS`): 20 section/screen, 100 item/screen, 200 dòng/scheme. Thực thi trong `screen.with_lock` / `scheme.with_lock` **sau** khi lấy khoá (tránh race POST đồng thời); mã lỗi `too_many_sections`, `too_many_items`, `too_many_scheme_rows`.
* Slot ↔ `screen_type` khớp nhau (`create_screen_id` chỉ nhận screen `create`…) được enforce ở model và `invariants_spec` (không có CHECK DB khả thi).
* Migration `modules/screens/db/migrate/20261005210000_create_screens.rb` (mã `20261005200000` đã được `type_schemes` dùng), `down` thả theo thứ tự phụ thuộc, không động bảng core, gỡ module chỉ bỏ 6 bảng.

Quy tắc model:

* `Screen`: `screen_type` **bất biến sau khi tạo** (`attr_readonly`; muốn đổi thì clone) — loại bỏ race "đổi type khi đang dùng". `before_destroy` chặn xoá (`cannot_be_deleted`). `active` đổi qua service.
* `ScreenSection`: `dependent: :delete_all` cho item (FK cũng cascade), một `reset_cache` ở `after_destroy`.
* Mọi thay đổi section/item đi qua `Screens::LayoutService` (khoá screen, kiểm giới hạn, chuẩn hoá `position`, chuyển item giữa section bằng remove+insert); **cấm** gán trực tiếp `section_id`/`position` từ params.
* `ScreenSchemeItem`: validation `at_least_one_screen`; mỗi `type_id` một lần; slot đúng `screen_type`.
* `ScreenScheme`: không xoá (`prevent_destroy`), `after_save`/`after_destroy` ⇒ `Screens::Resolver.reset_cache`; mirror F02 cho mọi model có ảnh hưởng.
* Cache chỉ trong phạm vi request (`RequestStore`); không `Rails.cache`.
* Custom field bị xoá ⇒ item mồ côi: resolver bỏ qua; dọn bằng `screens:repair` (hoặc hook nếu xác minh được, xem §2).

## 4. Xác thực & chẩn đoán

Mã ổn định dùng chung cho model, API và diagnostics:

| Mã | Điều kiện | Mức |
|---|---|---|
| `unknown_field` | `field_key` không thuộc registry (§5) | lỗi |
| `duplicate_field` | trùng `field_key` trong screen | lỗi |
| `context_mismatch` | screen gán sai slot | lỗi |
| `invalid_context` | context ngoài 4 giá trị | lỗi (422) |
| `invalid_width`, `invalid_position` | ngoài miền cho phép | lỗi |
| `too_many_sections` / `too_many_items` / `too_many_scheme_rows` | vượt giới hạn §3 | lỗi |
| `in_use`, `cannot_be_deleted` | thao tác bị chặn vì đang dùng | lỗi |
| `required_not_placed` | xem dưới | lỗi (Tầng 1) / cảnh báo (Tầng 2) |
| `hidden_and_required` | **mã kế thừa từ F02**; F03 không tự sinh | chỉ hiện khi F02 báo |
| `hidden_but_placed` | field bị F02 hidden nhưng có trên screen | cảnh báo |
| `unavailable` | field không khả dụng ở project/type | cảnh báo |
| `empty_create_screen` | screen create không item | cảnh báo |

**Tập bắt buộc** cho `(project, type)` = `subject` ∪ `project.type_variant(type).required_attributes` (key native và `custom_field_<id>`) ∪ custom field `is_required` đang active ở project (`project.all_work_package_custom_fields`) ∪ field F02 `required?`; **trừ** field có default (F02 `default_value` hoặc custom field default). Một field coi là *đã đặt* khi có item `visible = true` trên screen (item `visible = false` = chưa đặt; đây là cách F03 hiện thực "required + hidden không hợp lệ" của idea).

**Tầng 1 — chặn khi lưu (type-independent hoặc có chặn trên):**

1. *Screen in use*: một screen đang là `create_screen` của ≥1 dòng scheme **phải** có `subject` với `visible = true`. Kiểm tra khi xoá/ẩn item `subject` hoặc khi lưu layout. Screen chưa dùng thì chỉ cảnh báo `empty_create_screen`/thiếu subject (cho phép dựng dần).
2. *Lưu `ScreenSchemeItem` có `create_screen`*: tập bắt buộc đầy đủ ở trên, **chỉ cho type của dòng đó**, tính theo các project dùng scheme, gom theo `(rule_set, variant)` và `for_many` theo lô 500; nếu số project > 5000 thì **không chặn**, hạ xuống cảnh báo "bỏ qua kiểm tra do quy mô". Lỗi gom thành một 422 liệt kê `field → type → project` (tối đa 10, "+N nữa").

**Tầng 2 — cảnh báo/diagnostics (không bao giờ chặn):** mọi thay đổi ở F02 sau khi gán; gán scheme cho project (`PUT … screen_scheme`) không chặn; lưu `Screen` **không** chặn vì trạng thái F02/project (tránh lỗi do người khác gây ra). Kết quả hiện ở banner admin, project preview và `diagnostics` của resolver.

`visible = false` chỉ ẩn vị trí; không bao giờ làm hiện field mà F02/native ẩn.

## 5. Registry field đặt được (`Screens::Fields`)

* Toàn cục hợp lệ: `TypeVariant.all_work_package_form_attributes.keys` ∪ extras `%w[subject description status]` ∪ module đăng ký (`register(key, label:)`), trừ `%w[id created_at updated_at author type project]`; key khớp `/\A[a-z_][a-z0-9_]{0,63}\z/`. `custom_field_<id>` hợp lệ nếu `WorkPackageCustomField` tồn tại.
* Theo ngữ cảnh: `variant = project.type_variant(type)`; `variant.passes_attribute_constraint?(key, project:)`; variant nil ⇒ coi là khả dụng (fail-open).
* `watchers` **không** có trong registry V1 (không phải form attribute native); ví dụ `watchers` trong idea chỉ minh hoạ; module khác đăng ký được. Kịch bản test dùng `assignee`/`priority`.
* Nhãn: `TypeVariant.translated_work_package_form_attributes`. Key dùng chung không gian tên với `FieldRules::Fields` nên `hidden?(key)` tra thẳng (field ngoài 9 key native của F02 luôn `hidden? = false`).

## 6. Resolver

```ruby
Screens::Resolver.for(project, type, context)                      # => ResolvedScreen
Screens::Resolver.for_many(project_ids:, type_ids:, contexts:)     # => { [pid, tid, ctx] => ResolvedScreen }, tối đa 500 khoá, vượt ⇒ ArgumentError
```

Cache: `RequestStore.store[:screens_resolved][[project_id, type_id, context.to_sym]]`. `reset_cache` gọi từ callbacks model và (nếu có) `FieldRules::Resolver.reset_cache` để `state` không cũ.

Thuật toán:

1. `context` thuộc `%i[create edit view transition]`, nếu không ⇒ `ArgumentError`.
2. Type không bật trong project (`project.type_variant` không có `ProjectType`) ⇒ `native`, `reason: type_not_in_project` (API trả 404, §7).
3. Scheme: `ProjectScreenScheme` + scheme active; không có ⇒ `native` `no_scheme`/`scheme_inactive`. Dòng của type: không có ⇒ `type_not_in_scheme`.
4. Chọn screen theo `FALLBACKS = { create: [:create], edit: [:edit], view: [:view, :edit], transition: [:transition] }`: slot đầu tiên **non-null, screen active, `screen_type` khớp slot**. Slot bị bỏ ghi `diagnostics.skipped` (`{slot, screenId, reason: inactive|type_mismatch}`). Không slot nào dùng được ⇒ `native` `no_usable_screen`.
5. Nạp một lần `Screen` đã chọn kèm `sections: :items` (không N+1).
6. **Diagnostics tính trên tập item chưa lọc**, rồi mới lọc: bỏ `visible = false`; bỏ không `available?` (`unavailable`); bỏ F02 `hidden?` (`hiddenButPlaced`). `requiredNotPlaced` chỉ cho `create`.
7. F02 có: gắn `state = { required, readOnly, defaultValue }` cho từng field và `stateSource: "field_rules"`; không có: `state: null`, `stateSource: null`.
8. Trả `ResolvedScreen` immutable (`Data.define`).

Fail-open: `rescue StandardError` ⇒ `OpenProject.logger.error` + `Rails.error.report(e, handled: true, context: { project_id:, type_id:, context: })`, trả `native` với `reason: error`, `diagnostics.error = true`. Cờ module-local `::Screens::Resolver.raise_on_error` (mặc định `false`) cho phép test kiểm chứng re-raise; không đổi `spec_helper` của repo. Không ghi DB trong resolver.

## 7. API v3 (HAL)

Mount: `add_api_endpoint "API::V3::Root"` (screens, screen_schemes) và `add_api_endpoint "API::V3::Projects::ProjectsAPI", :id` (`ProjectScreensAPI`).

```text
GET    /api/v3/screens                              (authorize_logged_in)  filters, offset/pageSize
POST   /api/v3/screens                              (admin) {name, description, screenType}
GET    /api/v3/screens/{id}                         (logged in) kèm sections + items
PATCH  /api/v3/screens/{id}                         (admin) {name?, description?, active?}   (screenType read-only)
PUT    /api/v3/screens/{id}/layout                  (admin) thay toàn bộ layout; If-Match: updatedAt
POST   /api/v3/screens/{id}/sections                (admin)   [Slice 4]
PATCH  /api/v3/screens/{id}/sections/{sid}          (admin)   [Slice 4]
DELETE /api/v3/screens/{id}/sections/{sid}          (admin)   [Slice 4]
POST   /api/v3/screens/{id}/items                   (admin)   [Slice 4]
PATCH  /api/v3/screens/{id}/items/{iid}             (admin)   [Slice 4]
DELETE /api/v3/screens/{id}/items/{iid}             (admin)   [Slice 4]
GET    /api/v3/screen_schemes[/{id}]                (logged in)
POST   /api/v3/screen_schemes                       (admin)
PATCH  /api/v3/screen_schemes/{id}                  (admin) {name?, description?, active?, typeItems?}
GET    /api/v3/projects/{id}/screen_scheme          (assign_screen_scheme | admin)
PUT    /api/v3/projects/{id}/screen_scheme          (assign_screen_scheme) → 204
GET    /api/v3/projects/{id}/types/{type_id}/screens/{context}   (view_work_packages)
```

* **Không có** `DELETE` cho Screen/Scheme, **không có** `/activate|/deactivate` (dùng `PATCH {active}` như F02; deactivate screen đang dùng được phép, resolver fallback §6).
* Tra cứu lồng nhau theo cha: `screen.sections.find(sid)`, `screen.items.find(iid)` (sai ⇒ 404); `sectionId` trong body tra theo cùng cách; FK phức hợp là lớp thứ hai.
* `position`: 1-based, **kẹp** vào `[1, số_anh_em+1]` (không lỗi); PATCH giữ nguyên vị trí là no-op; chuyển section = `sectionId`+`position` trong một thao tác nguyên tử. Editor lưu bằng `PUT layout` một lần (tránh PATCH từng item chạy đua).
* `typeItems`: `[{ "_links": { "type", "createScreen", "editScreen", "viewScreen", "transitionScreen" } }]`; input chấp nhận cả `typeId` (như `scheme_params` của F02). `PATCH` có `typeItems` ⇒ thay toàn bộ danh sách; không có ⇒ giữ nguyên. Tối đa 200 phần tử, kiểm **trước** khi truy DB (`too_many_scheme_rows`).
* `PUT … screen_scheme`: `{ "schemeId": <id> }` hoặc `{ "_links": { "screenScheme": { "href" } } }`; scheme phải tồn tại và active, sai ⇒ 422; `schemeId: null` ⇒ về native (**Q-E**). Project lấy **chỉ từ URL**.
* Resolver endpoint: 404 nếu project không `visible` với người dùng hoặc type không bật trong project (kể cả type không tồn tại); 403 nếu thiếu `view_work_packages`; `context` sai ⇒ 422 `invalid_context` (kiểm trước mọi truy vấn). `diagnostics` chỉ trả cho admin hoặc người có `assign_screen_scheme`; người khác nhận `{}`. `Cache-Control: private`.

Phản hồi resolver (`_type: "ScreenLayout"`):

```json
{
  "source": "screen", "reason": null, "context": "create", "stateSource": "field_rules",
  "_links": { "self": {}, "project": {}, "type": {}, "screen": {},
              "schema": { "href": "/api/v3/work_packages/schemas/{pid}-{tid}" } },
  "sections": [ { "id": 1, "name": "General", "position": 1,
      "fields": [ { "key": "subject", "label": "Subject", "position": 1, "width": "full",
                    "state": { "required": true, "readOnly": false, "defaultValue": null } } ] } ],
  "diagnostics": { "unavailable": [], "hiddenButPlaced": [], "requiredNotPlaced": [], "skipped": [] }
}
```

`source: "native"` ⇒ `sections: []`, `reason` ∈ `no_scheme|scheme_inactive|type_not_in_scheme|no_usable_screen|error`, client dùng `_attributeGroups` của schema. Tên `state` dùng cùng ngôn ngữ F02 (`defaultValue`).

Ánh xạ lỗi → định danh API v3: `unknown_field`, `invalid_width`, `invalid_position`, `duplicate_field`, `context_mismatch`, `invalid_context`, `too_many_*` ⇒ `PropertyConstraintViolation` (422, `details.attribute`); `required_not_placed` (Tầng 1) ⇒ `MultipleErrors` (422); `in_use` (do `ScreenService` phát khi thao tác bị chặn vì đang dùng) và `cannot_be_deleted` (model `destroy`) ⇒ 422 `PropertyConstraintViolation`; `screenType` đổi ⇒ `PropertyIsReadOnly`; body sai ⇒ `InvalidRequestBody`; `If-Match` lệch ⇒ `UpdateConflict`, thiếu ⇒ 428. ETag là cơ chế mới (không có tiền lệ F02): `screen.updated_at.utc.iso8601(6)`, `GET` trả header `ETag`. Cảnh báo không phải lỗi: trả trong `diagnostics` của 200/201.

* `add_api_path`: `screens`, `screen`, `screen_layout`, `screen_sections`, `screen_section`, `screen_items`, `screen_item`, `screen_schemes`, `screen_scheme`, `project_screen_scheme`, `project_type_screen_layout`.
* OpenAPI: `docs/api/apiv3/paths/` và `docs/api/apiv3/components/schemas/*_model.yml` (+ `*_collection_model.yml`) **cho từng endpoint trong lát phát hành nó**.

### 7.1 Ánh xạ tên idea ↔ spec

| Idea | Spec |
|---|---|
| `issue_type_id` | `type_id` (DB), `typeId`/`_links.type` (API) |
| `screen_scheme_id` | `scheme_id` |
| `ScreenResolver.for(project:, issue_type:, context:)` | `Screens::Resolver.for(project, type, context)` |
| `/api/jira/...`, `/screen-schemes` | `/api/v3/...`, `/screen_schemes` |

## 8. Permission, menu, UI

* Permission `assign_screen_scheme` (trong `project_module nil`, `permissible_on: :project`, `require: :member`; controller `projects/settings/screen_scheme` `show update`). Quản lý screen/scheme: admin.
* Menu: `:admin_menu` `:screens` (parent `:admin_work_packages`), Schemes qua điều hướng phụ như F02; `:project_menu` `:settings_screen_scheme` (parent `:settings`).
* Routes: `admin/screens`, `admin/screen_schemes` (`except: %i[show destroy]`, member `clone/activate/deactivate`), `projects/:id/settings/screen_scheme` (`show update`). **Không** có route `confirm`: `update` render lại view `confirm` với 422 đến khi `confirm=1`.
* CSRF bật (kế thừa `ApplicationController`, `require_admin`); strong params theo action (`screen`: `name, description`, `screen_type` chỉ khi tạo; `item`: `section_id, field_key, position, width, visible`); tên render qua auto-escape; `aria-live` đặt bằng `textContent`.

**Editor Screen:** một form lưu cả layout (một lần submit ⇒ một lần xác nhận, đồng thời là đường không-JS). Trạng thái rỗng: không section ⇒ "Chưa có section" + `+ Add section`; section rỗng ⇒ "Kéo field vào đây" + `Add field`. Bộ chọn field nhóm Native / Custom fields, có tìm kiếm, loại field đã đặt; không-JS dùng `<select>` + nút Add. Mỗi item: ⋮ menu có **Up / Down / Move to section…** (đường chính không kéo-thả), width, visible. Kéo-thả (HTML5 DnD) và Alt+↑/↓ là bổ sung; sau khi di chuyển, focus trả về item; thông báo `aria-live`: "Subject moved to General, position 2 of 5". Không-JS: ô số `position` + "Save order". Nhãn cảnh báo/lỗi luôn có icon + chữ (không chỉ màu).

**Banner:** lỗi Tầng 1 là banner danger (liệt kê field/type + liên kết tới dòng scheme); cảnh báo (`hiddenButPlaced`, `unavailable`, `empty_create_screen`, Tầng 2) là banner warning, không chặn, hiện lại ở project preview.

**Xác nhận (FR-25):** lưu layout của screen đang dùng ⇒ view confirm nêu số scheme/project/type bị ảnh hưởng, một lần mỗi lần lưu.

**Clone:** tạo **bản sao riêng** tên "Copy of X", sao chép section/item/width/visible, `active = false`, `screen_type` giữ nguyên.

**Schemes:** bảng Type × (Create/Edit/View/Transition) chọn screen bằng dropdown lọc theo `screen_type` + active; `caption`, `<th scope>`; hiển thị lỗi/cảnh báo §4 ngay trong ô.

**Project Settings → Screen scheme:** dropdown scheme (+ "Native layout", Q-E) và bảng **Layout hiệu lực** Type × context: mỗi ô có badge `screen`/`native` kèm lý do (`view→edit`, `scheme inactive`, `screen inactive`…), cột "Overrides native" liên kết tới form configuration của type. **Field inspector** dưới preview: liệt kê field đã đặt với chip `hidden by field rules` / `unavailable` / `not visible`, lấy từ cùng `diagnostics` (không thêm logic).

Frontend: controller mới `screens--sortable` tại `frontend/src/stimulus/controllers/dynamic/screens/sortable.controller.ts` + đăng ký ở `frontend/src/stimulus/setup.ts` (file frontend core, không động Ruby core/bảng core), copyright header theo CLAUDE.md. Chuỗi UI chỉ cần `en.yml`, không hard-code.

## 9. Bảo mật, hiệu năng, an toàn

* Authz server-side mọi action; GET định nghĩa screen/scheme cho người đã đăng nhập (giống F02); ghi = admin; không rò layout/diagnostics qua type không bật hoặc project không thấy.
* Giới hạn đầu vào: `items[]`/`typeItems` ≤ 200 trước khi truy DB; `position` ngoài miền ⇒ `invalid_position` ở admin form, kẹp ở API; `field_key` regex + registry; `width` enum; `name` ≤ 255; mọi giới hạn có validation model và CHECK DB nếu khả thi.
* Khoá: mọi thay đổi layout/scheme trong `with_lock` + transaction; `RecordNotUnique` ⇒ lỗi validation.
* Hiệu năng: resolver ≤ 4 truy vấn cho một `for`; `for_many` không đổi số truy vấn khi tăng project; "Used by" trong danh sách tính bằng `GROUP BY` (như `@item_counts` của F02); index trên 4 cột `*_screen_id`, `project_screen_schemes.scheme_id`, `(section_id, position)`, `(screen_id, field_key)`; tập bắt buộc gom theo `(rule_set, variant)`.
* Cache chỉ trong request; không có cache chéo process.
* Migration/rollback: rollback test có dữ liệu; xoá Type chỉ cascade `screen_scheme_items`, `screens` giữ nguyên; xoá project cascade `project_screen_schemes`.
* Quality gates: rubocop (0 offense), erb_lint, eslint, `npm run typecheck`, copyright header cho `.ts` mới (`rake copyright:update_typescript`), lefthook.

## 10. Rủi ro

Hai nguồn layout gây nhầm (giảm bằng bảng Layout hiệu lực/inspector); `all_work_package_form_attributes` phụ thuộc representer core (boot guard + test `subject`); lệch với F02 sau khi rule đổi (chỉ chẩn đoán); screen dùng chung sửa gây tác động rộng (xác nhận); tập bắt buộc quy mô lớn (lô + ngưỡng 5000); custom field mồ côi; kéo-thả dễ flaky (test chính là bàn phím/không-JS); thêm file vào core frontend.

## 11. Kiểm thử & Acceptance

Mirror `modules/field_rules/spec`:

```text
spec/models/{screen,screen_section,screen_item,screen_scheme,screen_scheme_item,project_screen_scheme}_spec.rb
spec/services/screens/{resolver,fields,layout_service,scheme_service,coverage_validation,repair}_spec.rb
spec/permissions/assign_screen_scheme_spec.rb
spec/requests/api/v3/{screens,screen_layout,screen_schemes,project_screen_scheme,project_screen_layout}_api_spec.rb
spec/requests/admin_screens_params_spec.rb          # screen_type không cho phép sau tạo, section_id/screen_id của screen khác
spec/features/admin/{screens,screens_reorder,screen_schemes}_spec.rb
spec/features/projects/settings/screen_scheme_spec.rb
spec/lib/open_project/screens/{fail_open,field_rules_disabled,core_dependencies}_spec.rb
spec/db/{invariants,rollback_safety,rollback_with_data}_spec.rb
spec/tasks/screens_repair_rake_spec.rb
spec/factories/screen_factory.rb
```

Bất biến cần test: `item.screen_id == section.screen_id` (kể cả ghi SQL thô), unique `(screen_id, field_key)`, `position` liên tục sau mỗi thay đổi, CHECK `screen_type`/`width`, screen đang dùng không xoá được, `screen_type` không đổi được, giới hạn đúng khi POST đồng thời. Ma trận permission mỗi endpoint: ẩn danh (401), không phải thành viên (403/404), thành viên thiếu quyền (403), có `assign_screen_scheme` (200), admin; resolver còn thêm: type không bật, project private/archived. Query count: `Resolver.for` ≤ 4, `for_many` không đổi giữa 1 và 50 project. DnD: một happy-path system spec; phần chính bằng bàn phím và không-JS (`rack_test`), kiểm `aria-live`, axe.

Acceptance: idea-03 §16–§17, cộng: `source = native` + `reason` đúng cho từng trường hợp; fallback `view → edit` và `skipped` đúng; item `visible = false`/F02-hidden không có trong `fields` nhưng có trong `diagnostics`; deactivate scheme đang gán ⇒ project về native; xoá Type ⇒ screens còn; lỗi giả lập trong resolver ⇒ tạo/sửa work package vẫn chạy, có log + `Rails.error.report`; module chạy khi F02 vắng; `subject` placeable; không có "jira" trong tên bảng/class/route/permission/menu/i18n.

## 12. Cắt lát

| Lát | Nội dung |
|---|---|
| **1** | Migration + models + `Screens::Fields` + `Resolver` + `GET …/screens/{context}` + `GET/PUT …/screen_scheme` + trang project settings (bảng Layout hiệu lực, inspector); seed bằng console/factory |
| **2** | Admin UI Screen (editor một form, kéo-thả, clone, confirm) + `GET/POST/PATCH /screens` + `PUT /screens/{id}/layout` |
| **3** | Screen Scheme (admin UI + API `typeItems`), gán project hoàn chỉnh, Tầng 1/Tầng 2 validation, banner |
| **4** | API chi tiết section/item, `for_many`, `screens:repair`, hook dọn custom field (nếu xác minh được) |

`transition`: giữ enum, slot, cột ma trận và context ở lát 1–3 (rẻ), không có UI/logic riêng.

## 13. Quyết định cần chủ sản phẩm xác nhận

1. **Q-C (thu hẹp):** idea yêu cầu từ chối khi field bắt buộc không có trên screen tạo. Spec chỉ chặn Tầng 1 (mục §4) và hạ phần phụ thuộc F02/project thành cảnh báo. Mặc định: như spec; đổi lại nếu muốn chặn rộng hơn (đánh đổi: lỗi do người khác gây ra, chi phí).
2. **Q-E (mới, chưa được xác nhận):** cho phép `schemeId: null` để quay về native. Mặc định: cho phép.
3. **Context sai:** 422 `invalid_context` (theo idea) thay vì 404/400 kiểu API v3.
4. **Field "mồ côi":** dọn bằng `screens:repair` nếu không có hook sạch cho việc xoá custom field.
5. Q-A (đính kèm `state`), Q-B (fallback `view → edit`), Q-D (không ghi native): giữ mặc định của idea.
