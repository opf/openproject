# Type Scheme — Design Spec

Nguồn: [docs/ideas/idea-01.md](../../ideas/idea-01.md) · Ngày: 2026-10-02 · Nền tảng: OpenProject (repo này, Rails 8.1)

## 1. Mục tiêu

Thêm lớp quản trị **Type Scheme** (idea gọi là Issue Type Scheme) giữa Project và Work Package Type:
Project → Scheme → danh sách Type được phép **tạo mới**, có thứ tự và Type mặc định.
Scheme chỉ tham chiếu `Type` native, không tạo Type mới, không sửa dữ liệu Work Package.

## 2. Kết quả discovery (đã kiểm chứng trong code)

| Chủ đề | Thực trạng | Hệ quả thiết kế |
|---|---|---|
| Type bật theo project | `Project#enabled_types` → `Type.enabled_in` qua bảng `project_types` (`app/models/projects/enabled_types.rb`). Mỗi dòng gắn một `TypeVariant`. | Đây là cơ chế native "Type nào dùng được trong project". |
| Gỡ Type native | `Projects::Types::RemoveService` **từ chối** nếu đã có WP dùng Type đó (`app/services/projects/types/remove_service.rb`). | **Không thể** hiện thực Scheme bằng cách đồng bộ vào `project_types`: US-05 (gỡ Bug khỏi Scheme, WP Bug cũ giữ nguyên) sẽ bị chặn. Scheme phải là lớp lọc riêng, giao với `enabled_types`. |
| Danh sách Type khi tạo/đổi Type | `WorkPackages::BaseContract#assignable_types` (`app/contracts/work_packages/base_contract.rb:205`) = `project.enabled_types`. `SpecificWorkPackageSchema` delegate sang đây, nên API v3 form/schema, Angular và dialog tạo WP (`work_packages/dialogs/creation.rb:71` dùng `.first`) cùng đọc một nguồn. | **Một điểm hook duy nhất**: lọc/sắp xếp tại `assignable_types`. |
| Validate Type | `validate_enabled_type` (`base_contract.rb:279`) chỉ chạy khi `type_context_changed?`. | WP cũ có Type ngoài Scheme vẫn hợp lệ khi sửa field khác. Thêm validation tương tự cho Scheme. |
| Cơ chế plugin | `modules/*` là Rails engine dùng `OpenProject::Plugins::ActsAsOpEngine` (`register`, `menu`, `add_api_endpoint`, `patches`), đăng ký trong `Gemfile.modules`. Mẫu nhỏ: `modules/job_status`, `modules/webhooks`. | Làm module mới `modules/type_schemes`. |
| Type/TypeVariant | Repo đã tách `Type` + `TypeVariant`. Scheme tham chiếu `types.id` (không tham chiếu variant). Variant theo project vẫn do `project_types` quyết định. | Không đụng variant. |
| Thứ tự Type | `Type.position` là global. | Thứ tự theo Scheme chỉ áp dụng ở `assignable_types` (xem 5). |
| Sự kiện | Có `OpenProject::Events::PROJECT_CREATED`; project mới nhận Type qua `Projects::SetAttributesService#set_default_types`. | Auto-assign Default Scheme subscribe PROJECT_CREATED. |

Quyết định lệch so với idea (cần xác nhận ở mục 9):
- **API** đặt trong API v3 (HAL, `add_api_endpoint "API::V3::Root"`) thay vì `/api/jira/...` trong idea (không dùng tên jira), để theo convention và authentication sẵn có.
- **Manage Scheme = admin** (menu Administration vốn chỉ dành admin); **Assign Scheme** là project permission mới.
- **Hai điểm chạm core, đều qua `prepend` từ trong module (không sửa file core)**: `WorkPackages::BaseContract#assignable_types`/`validate_enabled_type` (lọc + validate) và `WorkPackages::SetAttributesService#assign_default_type` (Type mặc định khi tạo không chỉ định Type, vì Angular không tự chọn Type).

## 3. Phạm vi

In: CRUD Scheme, thêm/gỡ/sắp xếp Type, Default Type, gán Scheme cho Project (1 Scheme / Project), lọc Type khi tạo WP (UI + API + validation), clone, deactivate, delete có guard, cảnh báo khi Scheme dùng bởi nhiều project hoặc gỡ Type đang có WP, API REST, permission, migration, Default Scheme tự gán cho project mới, migration dữ liệu có chế độ DRY RUN/AUTO/MANUAL.

Out: Field Configuration, Screens, Workflow, Backlog/Scrum (chỉ cung cấp `Resolver` để các feature sau dùng); thay đổi Type của WP có sẵn; per-scheme Type order thay đổi `Type.position` global.

## 4. Data model

```text
type_schemes      id, name (unique, not null), description, is_default bool, active bool, timestamps
type_scheme_items id, scheme_id FK, type_id FK -> types, position int, is_default bool, timestamps
                             UNIQUE(scheme_id, type_id)
project_type_schemes     id, project_id FK UNIQUE, scheme_id FK, timestamps
```

- FK `on_delete: :cascade` cho `type_id`, `project_id`, `scheme_id` (items), nên xoá Type hoặc Project không để lại dòng mồ côi. Việc xoá Type đang có WP đã bị core chặn (`Type#check_integrity`), module không cần xử lý thêm.
- `scheme.is_default` (Default Scheme cho project mới): tối đa 1 scheme `is_default = true` (partial unique index).
- `item.is_default`: đúng 1 item mặc định khi scheme `active` (khuyến nghị idea); partial unique index `(scheme_id) WHERE is_default`.
- Đặt tên theo convention của repo (WP "Type", bảng số nhiều snake_case như `project_types`, `type_variants`): bảng `type_schemes`, `type_scheme_items`, `project_type_schemes`; model `TypeScheme`, `TypeSchemeItem`, `ProjectTypeScheme`. Không dùng tiền tố/tên "jira" trong bảng, class, route, permission hay menu.

## 5. Hành vi

**Resolver** `TypeSchemes::Resolver.for_project(project) → scheme | nil` (cache trong request). Project không có scheme ⇒ hành vi native, không lọc.

**Allowed types khi tạo** = `project.enabled_types ∩ scheme.types`, sắp theo `scheme_item.position`, Type mặc định đứng đầu danh sách nếu chưa có thứ tự khác (để `assignable_types.first` và UI chọn đúng default). Nếu giao rỗng ⇒ fallback `enabled_types` và hiển thị cảnh báo ở project settings (tránh khoá tạo WP).

**Áp dụng cho**: WP mới và WP đổi Type. WP hiện có luôn giữ Type hiện tại trong danh sách của chính nó (Type hiện tại được cộng vào allowed khi model đã persisted), và validation chỉ chạy khi `type_context_changed?`.

**Không tự động đổi dữ liệu**: gỡ Type khỏi Scheme không đụng WP, không đụng `project_types`.

**Cảnh báo (UI)**: (a) sửa Scheme dùng bởi N project; (b) gỡ Type đang dùng bởi M WP trong các project của scheme.

**Delete**: chặn nếu còn project gán, liệt kê project. **Deactivate**: scheme inactive không còn lọc (project xem như chưa có scheme) và không gán được mới — ghi rõ trong UI.

**Clone**: tạo scheme mới `"<tên> - Custom"` với cùng items, không gán project.

**Uninstall/Compatibility**: bỏ module chỉ bỏ 3 bảng; `types`, `work_packages`, `project_types` không bị đụng.

## 6. Permission

- `manage_type_schemes`: admin (menu `Administration → Work packages → Type schemes`).
- `assign_type_scheme`: project permission (`permissible_on: :project, require: :member`), dùng cho mục Project Settings và API assign. View danh sách scheme/available types: bất kỳ member có `view_work_packages`.
- Enforce phía server ở controller/API; lọc contract áp dụng cho mọi user.

## 7. API (API v3, HAL)

```text
GET    /api/v3/type_schemes
GET    /api/v3/type_schemes/:id
POST   /api/v3/type_schemes           (admin)
PATCH  /api/v3/type_schemes/:id       (admin)
DELETE /api/v3/type_schemes/:id       (admin)
PUT    /api/v3/projects/:id/type_scheme   {scheme_id}   (assign_type_scheme)
GET    /api/v3/projects/:id/available_types              (view_work_packages)
```

Body create (`type_items: [{type_id, position, default}]`).

## 8. UI

- Admin: danh sách (Name, Projects, Status; actions Create/Edit/Clone/Deactivate/Delete), form với danh sách Type kéo-thả sắp xếp + radio Default, dùng Primer/ViewComponent + Turbo giống `Admin::Settings::ProjectPhaseDefinitionsController` và `acts_as_list`/drag handler đang có.
- Project Settings → Work packages → Type scheme: dropdown Scheme + danh sách Available Types.
- Create WP: không đổi UI; danh sách Type đã được lọc từ schema/contract.

## 9. Câu hỏi mở (có mặc định, đổi được)

1. API v3 (`/api/v3/type_schemes`) — theo convention của repo.
2. Manage = admin-only — mặc định: admin-only.
3. Đổi Type của WP có sẵn sang Type ngoài Scheme: mặc định **bị chặn** (giữ Type hiện tại).
4. Scheme `is_default` + gán tự động cho project mới: mặc định bật, admin có toggle.

## 10. Rủi ro

- `prepend` vào `WorkPackages::BaseContract`: nếu core đổi tên/hợp đồng `assignable_types`, spec hook sẽ vỡ ngay (có test bảo vệ).
- Frontend Angular có thể tự chọn default Type theo thứ tự `allowedValues`; cần xác minh ở Task 4 (spike). Nếu không, default chỉ có hiệu lực ở dialog Rails và API, và ghi nhận là giới hạn.
- Kết quả spike (Task 3), đã xử lý: Angular không tự chọn Type; khi không có `?type=` server chọn bằng `SetAttributesService#assign_default_type` (core: `project.enabled_types.first`). Module prepend thêm vào hàm này để chọn phần tử đầu của `Resolver.allowed_types` (default Scheme) khi có Scheme, nên default hoạt động end-to-end; không có Scheme thì giữ hành vi gốc.
- Type có `TypeVariant` theo project: Scheme không phân biệt variant (cùng Type ⇒ cùng được phép).

## 11. Acceptance

Theo mục 25 của idea, cộng: Type ngoài Scheme không xuất hiện trong schema API v3 `type.allowedValues` của form tạo WP; POST tạo WP với Type ngoài Scheme trả lỗi validation; WP cũ vẫn sửa được.

## 12. Quyết định sau review hội đồng (2026-10-03)

- **Thứ tự:** `Resolver.allowed_types` mặc định đặt Type default lên đầu để `assignable_types.first` (dialog tạo WP của core, `assign_default_type`) luôn chọn đúng default mà không sửa core. Các bề mặt do module kiểm soát (trang Project Settings, `GET projects/:id/available_types`) dùng `default_first: false`, hiển thị đúng thứ tự `position` như idea US-04 và đánh dấu default riêng.
- **Cache:** `Resolver.for_project` cache theo request trong `RequestStore`; reset khi model/`SchemeService` thay đổi dữ liệu. `update_columns`/SQL thô không reset (chỉ dùng trong test).
- **Unassign:** giữ nguyên, quyền `assign_type_scheme` do admin cấp cho role và bao gồm gỡ gán; ghi trong tài liệu.
- **Cảnh báo:** sửa bất kỳ Scheme nào đang gán cho ≥1 project đều qua trang xác nhận (không chỉ khi gỡ Type).
- **Activate/Deactivate:** có cả hai; deactivate gỡ cờ `is_default`.
- **Hoãn:** kéo-thả sắp xếp (hiện dùng ô số `position`), `PUT` với `scheme_id` không tồn tại trả 422.
