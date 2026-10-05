# Screens — Design Spec (Feature 03)

Nguồn: [docs/ideas/idea-03.md](../../ideas/idea-03.md) · Ngày: 2026-10-05 · Phụ thuộc: Feature 01 (`modules/type_schemes`), Feature 02 (`modules/field_rules`, phụ thuộc mềm)

Quyết định đã chốt (mặc định của idea, chưa có phản hồi khác): **Q-A** resolver đính kèm trạng thái field hiệu lực từ F02; **Q-B** fallback `view → edit → native`, các context khác `→ native`; **Q-C** field bắt buộc không có chỗ trên screen `create` ⇒ từ chối lưu; **Q-D** không ghi xuống `FormConfiguration` native; **Q-E** (mới) cho phép gỡ scheme khỏi project để về native.

## 1. Mục tiêu và phạm vi

Với một Project + Type + ngữ cảnh (`create`, `edit`, `view`, `transition`): **field nào nằm ở section nào, theo thứ tự nào**. Plugin chỉ lưu *layout*; không lưu dữ liệu field, không có model Field, không đổi required/hidden/read-only/default (thuộc F02).

In (V1): Screen / Section / Item, Screen Scheme (Type → screen theo ngữ cảnh), gán cho project, Resolver hợp nhất với trạng thái F02, kiểm tra xung đột khi lưu, admin UI (có kéo-thả), project settings, API v3, permission, migration, test, OpenAPI.

Out: workflow / transition logic (chỉ có abstraction), automation, hành vi field động, thay thế/ghi vào form configuration native, sửa Angular native, enforcement dựa trên screen, block không phải field (bảng liên quan, activity, relations — Feature 04), kế thừa, import/export screen.

## 2. Đối chiếu code (đã kiểm chứng)

| Chủ đề | Thực trạng | Hệ quả |
|---|---|---|
| Layout native | `ProjectType` gắn `variant` (`TypeVariant`) cho (project, type); variant gắn `FormConfiguration` có group `attribute` và `query`. Schema API v3 đưa ra qua `_attributeGroups` (`WorkPackageSchemaRepresenter#attribute_groups`). | Layout native là nguồn mặc định (`source: native`). F03 không đọc/ghi `FormConfiguration` (Q-D). |
| Một layout cho mọi ngữ cảnh | Tạo/sửa/xem dùng cùng `attribute_groups`. | Khoảng trống thật: ngữ cảnh + dùng chung. |
| Danh sách field | `TypeVariant.all_work_package_form_attributes` (key lấy từ `WorkPackageSchemaRepresenter.representable_attrs`) **loại** `EXCLUDED` (gồm `description`, `parent`, `version`, derived, `links`…) rồi thêm custom field. `description` vẫn nằm trong form qua group mặc định. | Registry `Screens::Fields` = form attributes **+** extras tường minh (`description`), trừ denylist; không suy từ `EXCLUDED` mù. |
| Khả dụng theo project | `type_variant.passes_attribute_constraint?(key, project:)`; custom field qua `custom_field_in_project?` (`project.all_work_package_custom_fields`). | Dùng để loại field không khả dụng ở runtime (không tự viết lại logic). |
| Tìm variant | Không có helper `variant_for`; `ProjectType.find_by(project:, type:)&.variant` hoặc `type.default_variant`. | Resolver tự tra, preload theo lô cho `for_many`. |
| F02 | `FieldRules::Resolver.for(project, type)` → `EffectiveConfiguration` (`hidden?`, `required?`, `read_only?`, `fields[key].default_value`, `source`), cache `RequestStore`, fail-open; `for_many(project_ids, type_ids)`. | F03 gọi qua guard `defined?(FieldRules::Resolver)`; F02 tắt ⇒ bỏ phần `state`. |
| Quy ước module | Engine `ActsAsOpEngine`, menu `:admin_menu` parent `:admin_work_packages`, `permission … permissible_on: :project, require: :member`, `add_api_endpoint`, `add_api_path`, `Gemfile.modules`, OpenAPI trong `docs/api/apiv3/paths` + `components`. | Sao chép mẫu `modules/field_rules`. |
| Điểm chạm core | F02 prepend contract/schema/set-attributes; F03 **không enforce** ⇒ không cần prepend nào. | Không có `assert_patch_targets!` ngoài kiểm tra `TypeVariant.all_work_package_form_attributes` tồn tại. |

Điểm cần xác minh khi implement (chưa kiểm chứng đủ trong lúc viết spec): (a) `watchers` không phải form attribute native nên không có trong registry mặc định (ví dụ `watchers` trong idea chỉ minh hoạ; module khác đăng ký qua `Screens::Fields.register`); (b) cách lấy tập required native của một (project, type): `subject` luôn required, custom field required qua `required_attributes` của variant (`custom_field_required?`).

## 3. Data model

```text
screens                id, name (unique, ≤255), description (≤5000),
                       screen_type string {create,edit,view,transition} (CHECK), active default true, timestamps
screen_sections        id, screen_id FK on_delete:cascade, name (≤255), position int, timestamps
                       UNIQUE(screen_id, name)
screen_items           id, screen_id FK on_delete:cascade, section_id FK on_delete:cascade,
                       field_key, position int, width string {full,half} default 'full' (CHECK),
                       visible bool default true, timestamps
                       UNIQUE(screen_id, field_key)   INDEX(section_id, position)
screen_schemes         id, name (unique, ≤255), description (≤5000), active default true, timestamps
screen_scheme_items    id, scheme_id FK on_delete:cascade, type_id FK types on_delete:cascade,
                       create_screen_id, edit_screen_id, view_screen_id, transition_screen_id
                       (FK screens, nullable, KHÔNG cascade), timestamps
                       UNIQUE(scheme_id, type_id)
project_screen_schemes id, project_id FK cascade UNIQUE, scheme_id FK (không cascade), timestamps
```

Quy ước đặt tên khớp F02 (`scheme_id`, `type_id`; idea gọi `issue_type_id`/`screen_scheme_id`). `field_key` không có FK; validate bằng registry (§5). Giới hạn: tối đa 20 section/screen, 100 item/screen, 200 dòng/scheme. `screen_items.screen_id` phải bằng `section.screen_id` (validation + test invariants như F02 `invariants_spec`). Migration `modules/screens/db/migrate/20261005200000_create_screens.rb`, đảo ngược được, không động bảng core; gỡ module chỉ bỏ 6 bảng.

Quy tắc model:

* `Screen`: `screen_type` **bất biến** khi screen đang được dùng trong scheme item; `before_destroy` chặn xoá (lỗi `cannot_be_deleted`); deactivate/activate/clone qua service.
* `ScreenSection`/`ScreenItem`: `acts_as_list` (section theo `screen_id`, item theo `section_id`), xoá section ⇒ xoá item (dependent destroy); xoá lẻ section/item được phép (sửa nội dung).
* `ScreenScheme`: không xoá (như `FieldRuleScheme`); mỗi `type_id` một lần; mỗi ô screen phải khớp `screen_type` (`context_mismatch`).
* `ProjectScreenScheme`: một project một scheme.
* `after_save`/`after_destroy` của mọi model ⇒ `Screens::Resolver.reset_cache`.

## 4. Ma trận hợp lệ (validate server-side khi lưu)

| Mã | Điều kiện | Mức |
|---|---|---|
| `unknown_field` | `field_key` không thuộc registry (§5) | lỗi |
| `duplicate_field` | trùng `field_key` trong screen | lỗi |
| `context_mismatch` | screen gán vào ô sai `screen_type` | lỗi |
| `invalid_context` | context ngoài 4 giá trị | lỗi (422 ở API) |
| `invalid_width` | width ngoài `full`/`half` | lỗi |
| `in_use` | thao tác bị chặn vì đang dùng (đổi `screen_type`, xoá) | lỗi |
| `required_not_placed` | (Q-C) với dòng scheme có `create_screen`, tồn tại field **bắt buộc không có default** mà không có item `visible = true` trên screen đó, xét mọi project dùng scheme | **lỗi khi lưu** |
| `hidden_but_placed` | field bị F02 `hidden` ở ít nhất một project dùng scheme nhưng nằm trên screen | cảnh báo |
| `unavailable` | field không khả dụng ở project/type | cảnh báo |
| `empty_create_screen` | screen `create` không có item nào | cảnh báo |

**Tập bắt buộc** cho `(project, type)` = `subject` ∪ `FieldRules::Resolver.for(project, type)` các field `required?` ∪ custom field required của variant; loại những field có `default_value`. Đây là cách hiện thực quy tắc idea "required + hidden không hợp lệ": một field bắt buộc mà không có vị trí hiển thị trên screen tạo (kể cả `visible = false`) bị từ chối. Kiểm tra chạy tại: lưu `ScreenSchemeItem` (kèm gán `create_screen`), và lưu `Screen` đang là `create_screen` của scheme item nào đó (từ chối nếu thay đổi gây vi phạm, liệt kê type/scheme bị ảnh hưởng). Thay đổi rule ở F02 sau đó **không** bị F03 chặn (F02 không biết F03); chỉ ghi nhận ở `diagnostics` và cảnh báo ở UI.

`visible = false` chỉ ẩn vị trí; không bao giờ làm hiện field mà F02/native ẩn.

## 5. Registry field đặt được (`Screens::Fields`)

`Screens::Fields.placeable?(key)` (toàn cục) và `Screens::Fields.available?(key, project:, type:)` (theo ngữ cảnh).

* Toàn cục hợp lệ: key ∈ `TypeVariant.all_work_package_form_attributes.keys` ∪ extras `%w[description]` ∪ đăng ký (`register(key, label:)`), trừ denylist `%w[id created_at updated_at author type project]`. `custom_field_<id>` hợp lệ nếu là `WorkPackageCustomField` tồn tại.
* Theo ngữ cảnh: `variant.passes_attribute_constraint?(key, project:)` với variant của (project, type).
* Key dùng cùng không gian tên với F02 (`FieldRules::Fields`), nên `FieldRules` `hidden?(key)` tra trực tiếp.
* Tên hiển thị: `TypeVariant.translated_work_package_form_attributes` (không tự dịch lại).

## 6. Resolver

`Screens::Resolver` (module function, như `FieldRules::Resolver`; cache `RequestStore[:screens_by_project_type_context]`):

```ruby
Screens::Resolver.for(project:, type:, context:)   # => ResolvedScreen
Screens::Resolver.for_many(project_ids, type_ids, context) # preload, tránh N+1
```

Thuật toán:

1. Validate `context ∈ %i[create edit view transition]`, sai ⇒ `ArgumentError` (API ⇒ 422).
2. Tìm `ProjectScreenScheme` active của project với scheme active; không có ⇒ `source: :native`.
3. Lấy `ScreenSchemeItem(type)`; chọn screen theo chuỗi fallback (Q-B): `view → edit`; chỉ chọn screen **active** và đúng `screen_type`. Không có ⇒ `native`.
4. Nạp section/item (một lần, order theo `position`).
5. Loại item: `visible = false`; không `available?`(ghi `diagnostics.unavailable`); F02 `hidden?` (ghi `diagnostics.hidden_but_placed`).
6. Nếu `FieldRules::Resolver` có: gắn `state = { required, readOnly, default, source }` cho từng field (Q-A).
7. Ghi `diagnostics.required_not_placed` khi context `create` thiếu field bắt buộc (như §4, dùng cho dữ liệu cũ/sau khi F02 đổi).
8. Trả `ResolvedScreen` immutable (`Data.define`) gồm `source`, `context`, `screen` (id, name), `sections` (id, name, position, `fields`: key, position, width, state), `diagnostics`.

Mọi `StandardError` ⇒ log `[screens] resolving failed, using native layout` và trả `ResolvedScreen.native(context)` (fail-open). Không ghi DB trong resolver.

## 7. API v3 (HAL)

Module `API::V3::Screens`; mount theo mẫu `modules/field_rules/lib/api/v3/field_rules`. Auth: ghi = admin (như F02); gán project = `assign_screen_scheme`; đọc resolver = `view_work_packages`.

```text
GET    /api/v3/screens                      collection (filter active, screenType)    admin
POST   /api/v3/screens                      {name, description, screenType}           admin
GET    /api/v3/screens/{id}                 kèm sections + items                       admin
PATCH  /api/v3/screens/{id}                 name, description                          admin
POST   /api/v3/screens/{id}/activate | deactivate                                       admin
POST   /api/v3/screens/{id}/sections        {name, position?}
PATCH  /api/v3/screens/{id}/sections/{sid} {name?, position?}
DELETE /api/v3/screens/{id}/sections/{sid}
POST   /api/v3/screens/{id}/items           {sectionId, fieldKey, position?, width?, visible?}
PATCH  /api/v3/screens/{id}/items/{iid}     {sectionId?, position?, width?, visible?}
DELETE /api/v3/screens/{id}/items/{iid}
GET/POST/PATCH /api/v3/screen_schemes[/{id}]   body: items: [{typeId, createScreen, editScreen, viewScreen, transitionScreen}]
POST   /api/v3/screen_schemes/{id}/activate | deactivate
PUT    /api/v3/projects/{id}/screen_scheme  {schemeId}                 assign_screen_scheme
GET    /api/v3/projects/{id}/types/{type_id}/screens/{context}         view_work_packages
```

* Không có `DELETE` cho Screen và Screen Scheme. `PUT … screen_scheme` thiếu/không tồn tại/inactive ⇒ 422 (**Q-E**, mặc định: `schemeId: null` được phép để quay về layout native, khác F01 vì F03 không có Default Scheme).
* `position` ghi vào item/section qua `PATCH`; service dịch chuyển phần còn lại trong transaction có lock row cha (`screen.with_lock`).
* Resolver response (`_type: "ScreenLayout"`): `source`, `context`, `_links.self`, `_links.screen` (khi `source = screen`), `sections[].fields[]` (`key`, `position`, `width`, `state?`), `diagnostics` (`unavailable`, `hiddenButPlaced`, `requiredNotPlaced`). `source = native` ⇒ `sections: []`.
* Lỗi theo cấu trúc API v3; mã ở §4. Context sai ⇒ 422 `invalid_context`.
* `add_api_path`: `screens`, `screen`, `screen_schemes`, `screen_scheme`, `project_screen_scheme`, `project_type_screen_layout`.
* OpenAPI: `docs/api/apiv3/paths/{screens,screen,screen_schemes,screen_scheme,project_screen_scheme,project_type_screen_layout}.yml` + components tương ứng.

## 8. Permission, menu, UI

* Permission: `assign_screen_scheme` (project, `require: :member`, controller `projects/settings/screen_scheme` `show update`). Quản lý screen/scheme: admin-only (`User.current.admin?`).
* Menu: `:admin_menu` `:screens` (`parent: :admin_work_packages`, controller `/admin/screens`), Screen Schemes truy cập qua điều hướng phụ của trang (như F02); `:project_menu` `:settings_screen_scheme` (parent `:settings`).
* Routes (`modules/screens/config/routes.rb`): `admin/screens` và `admin/screen_schemes` (`except: %i[show destroy]`, member `clone/activate/deactivate`, cộng `confirm` cho trang xác nhận), `projects/:id/settings/screen_scheme` (`show update`).
* Admin Screens: danh sách (Name, Type, Used by, Status; Edit/Clone/Deactivate/Activate; không Delete). Editor: danh sách section; mỗi section là danh sách item (tên field, ⋮ menu, width, visible); `+ Add section`; chọn field qua bộ chọn loại trừ field đã đặt; cảnh báo `unavailable`.
* Kéo-thả (HTML5 DnD) cho item ⇄ section và đổi thứ tự section, Stimulus controller `screens--sortable`; Lên/Xuống bằng Alt+↑/↓ với vùng `aria-live`; vị trí ghi vào ô số `position` (hoạt động khi tắt JS) — dùng lại mẫu `type-schemes--sortable-types` của F01 §13.3.
* Trang xác nhận khi sửa Screen/Scheme đang dùng (số scheme, project, type bị ảnh hưởng).
* Admin Screen Schemes: bảng Type × (Create/Edit/View/Transition) chọn screen bằng dropdown, lọc theo `screen_type` và `active`; hiển thị lỗi/cảnh báo §4 trong bảng.
* Project Settings → Work packages → Screen scheme: dropdown scheme (+ tuỳ chọn "Native layout" theo Q-E) và xem trước theo (type, context) với nhãn nguồn.
* Primer/ViewComponent + Turbo + Stimulus; i18n qua `config/locales/en.yml`; a11y: nhãn, `caption`, bảng responsive.

## 9. Bảo mật, hiệu năng, an toàn

* Authz server-side mọi action; strong params; giới hạn kích thước (§3); input sai kiểu ⇒ 4xx không 500; không `html_safe`; transaction + lock khi sửa; `RecordNotUnique` ⇒ lỗi validation.
* Cache resolver theo request + `for_many`; không truy vấn trong vòng lặp work package; index `(scheme_id,type_id)`, `project_id`, `(screen_id, field_key)`, `(section_id, position)`.
* Fail-open (§6); rake `screens:repair` (xoá item mồ côi: `custom_field_<id>` đã xoá; chuẩn hoá `position`).
* Migration không động bảng core.
* Cập nhật ghi nhận: không có thay đổi hành vi native khi project chưa gán scheme.

## 10. Rủi ro

Hai nguồn layout (native vs screen) gây nhầm — UI luôn hiện `source`; đọc `all_work_package_form_attributes` phụ thuộc cấu trúc representer của core (boot guard kiểm tra tồn tại); sửa screen dùng chung có tác động rộng (trang xác nhận); lệch với F02 sau khi rule đổi (chỉ `diagnostics`); `required_not_placed` có thể chặn sửa screen — thông điệp lỗi phải liệt kê chính xác type/field; custom field mồ côi (bỏ qua + repair).

## 11. Acceptance

Theo idea-03 §16 và §17 (10 kịch bản), cộng: `source = native` khi project không có scheme; fallback `view → edit → native` đúng; item `visible = false` hoặc F02-hidden không xuất hiện trong `fields`; lỗi giả lập trong resolver không làm hỏng tạo/sửa work package; module chạy khi F02 tắt; không có "jira" trong tên bảng/class/route/permission/menu/i18n; rubocop, erb_lint sạch; rollback migration an toàn (có `rollback_safety_spec`, `invariants_spec` như F02).
