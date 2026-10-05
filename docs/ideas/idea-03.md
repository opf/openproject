# Feature 03 — Issue Screen & Layout

> **Loại tài liệu:** idea brief — đầu vào cho AI coding agent viết **spec → plan → implementation**.
> **Phụ thuộc:** Feature 01 (`modules/type_schemes`), Feature 02 (`modules/field_rules`).
> **Module đề xuất:** `modules/screens`.

## 0. Cách dùng tài liệu này (dành cho AI agent)

1. Đọc toàn bộ tài liệu, sau đó đọc `docs/superpowers/specs/2026-10-02-type-scheme-design.md` và `2026-10-03-field-rules-design.md` để lấy quy ước đã chốt.
2. **Kiểm chứng các giả định ở mục 3 trong code thật** trước khi viết spec; nếu code khác mô tả, ghi lại chênh lệch trong spec và đề xuất điều chỉnh, không tự suy diễn.
3. Viết spec vào `docs/superpowers/specs/<ngày>-screens-design.md` (cùng định dạng hai spec trước), sau đó viết plan chia task nhỏ có thể kiểm thử, rồi mới implement.
4. Mọi mục đánh dấu **[Quyết định mở]** có giá trị mặc định; dùng mặc định nếu chủ sản phẩm chưa trả lời, và ghi vào spec.
5. Các mục **MUST / MUST NOT** là ràng buộc cứng. Các mục **SHOULD** là mong muốn.
6. Jira chỉ xuất hiện để so sánh khái niệm. **MUST NOT** dùng tên Jira trong bảng, class, route, permission, menu, i18n hay API.

## 1. Ý tưởng cốt lõi

OpenProject đã có **Form configuration** theo Work Package Type (thêm/bớt/sắp xếp attribute; Enterprise có thêm section và bảng work package liên quan). Vì vậy:

> Feature 03 **không** xây lại form configuration và **không** thay thế nó.
> Feature 03 là **lớp điều phối Screen / Scheme đặt phía trên** Form Configuration native và Field Configuration (Feature 02).

Khoảng trống cần lấp, so sánh với mô hình quản trị của Jira (chỉ để hiểu bài toán):

* Layout native chủ yếu phụ thuộc **Work Package Type** (và tổ hợp Project + Type trong schema API).
* Cần thêm khả năng quyết định **screen nào dùng cho từng ngữ cảnh** (create / edit / view / transition) và **dùng chung screen giữa nhiều type/project** thông qua scheme.

Nguyên tắc nền tảng:

> **Screen không sở hữu dữ liệu field.** Screen chỉ quyết định: field nào xuất hiện, xuất hiện ở đâu, thứ tự, section nào, screen nào dùng field đó.
> `required`, `hidden`, `read-only`, `default` **thuộc Feature 02 – Field Configuration**.
> **Configuration ≠ Layout.**

## 2. Mục tiêu và phi mục tiêu

### 2.1 Mục tiêu

* Định nghĩa **Screen** theo ngữ cảnh `create`, `edit`, `view`, `transition`.
* Mỗi Screen gồm **Section** có thứ tự; mỗi Section gồm **Item** (field) có thứ tự.
* Định nghĩa **Screen Scheme**: ánh xạ **Issue Type → (create, edit, view, transition screen)**.
* Gán **Screen Scheme cho Project**.
* **Resolver** trả về layout hiệu lực cho `(project, issue type, context)`.
* **REST API** để quản lý Screen/Scheme và để frontend lấy layout đã resolve.
* **UI quản trị** để tạo/sửa Screen (section, field, thứ tự, kéo-thả), Scheme, và gán cho Project.
* **Xác thực xung đột** với Field Configuration khi lưu.

### 2.2 Phi mục tiêu (MUST NOT)

* Không tạo model **Field** mới (không có `JiraField`/`Field`); field luôn là `field_key` trỏ tới attribute work package hoặc custom field native.
* Không tạo model **Work Package** mới.
* Không implement **workflow**, transition validator, automation, hành vi field động.
* Không thay thế native Form Configuration.
* Không sửa OpenProject core nếu chưa bắt buộc; ưu tiên extension point / prepend có boot guard như F01/F02. Không thêm cột/bảng vào bảng core.

## 3. Ngữ cảnh codebase cần xác minh

Các điểm sau được rút ra khi review trước đó; agent phải kiểm chứng lại khi viết spec.

| # | Giả định | Nơi kiểm chứng |
|---|---|---|
| C1 | Mỗi project dùng một `TypeVariant` cho mỗi type; variant gắn `FormConfiguration` gồm group (attribute group và query group). | `app/models/form_configuration.rb`, `form_configuration_group.rb`, `type_variant.rb`, `project_type.rb` |
| C2 | Schema API v3 đưa layout native qua `_attributeGroups` theo (project, type, variant). | `lib/api/v3/work_packages/schema/work_package_schema_representer.rb` |
| C3 | Một field không nằm trong group nào của form configuration thì không hiện (hidden native). Extension point `Type.add_constraint` có **một callable cho mỗi attribute**. | `app/models/type/attributes.rb` |
| C4 | `FormConfiguration*` đã tồn tại trong core → tránh trùng tên; dùng tiền tố `Screen*`. Chưa có class/bảng `Screen*` nào. | grep toàn repo |
| C5 | F01 và F02 đã chốt: API v3 HAL (không `/api/jira`), module trong `modules/*`, manage = admin, assign = project permission, không xoá thứ đang dùng (deactivate), fail-open, cache theo request, không sửa file core. | hai spec trong `docs/superpowers/specs/` |
| C6 | `FieldRules::Resolver.for(project, type)` trả cấu hình hiệu lực của field (hidden/required/read_only/default/source). | `modules/field_rules/app/services/field_rules/` |
| C7 | OpenProject native không có "transition screen"; đổi status là một field, Workflow chỉ quyết định status nào chọn được. | core |

## 4. Thuật ngữ

| Thuật ngữ | Nghĩa |
|---|---|
| Screen | Bố cục có tên cho một ngữ cảnh: danh sách Section, mỗi Section có Item. |
| Section | Nhóm field có tên và thứ tự trong một Screen. |
| Item | Một field được đặt vào Section tại một vị trí. Trỏ tới `field_key`. |
| `field_key` | Khoá thuộc tính work package: `subject`, `description`, `status`, `priority`, `assignee`, `due_date`, `custom_field_<id>`… Cùng cơ chế với Feature 02. |
| Screen Scheme | Bảng ánh xạ Issue Type → Screen cho từng ngữ cảnh. |
| Context | `create`, `edit`, `view`, `transition`. |
| Issue Type | Native OpenProject `Type` (hoặc resolver của Feature 01). **Không** có Issue Type mới. |
| Resolver | Service trả layout hiệu lực cho `(project, issue_type, context)`. |

## 5. Quan hệ giữa các feature

| Feature | Trả lời câu hỏi |
|---|---|
| Issue Type Scheme (F01) | Issue Type nào được phép dùng? |
| Field Configuration (F02) | Field có visible / required / read-only / default không? |
| **Screen & Layout (F03)** | **Field nằm ở đâu và xuất hiện trên screen nào?** |
| Screen Scheme (F03) | Với context này (project + type) dùng screen nào? |
| Workflow | Issue chuyển trạng thái thế nào? (ngoài phạm vi) |

Chuỗi cấu hình:

```text
Project
   ↓  (project → screen scheme)
Screen Scheme
   ↓  (issue type → screens)
Issue Type ─┬─ Create screen
            ├─ Edit screen
            ├─ View screen
            └─ Transition screen
```

Ví dụ:

```text
Bug
 ├── Create → Bug Create Screen
 ├── Edit   → Bug Edit Screen
 └── View   → Bug View Screen

Story
 ├── Create → Story Create Screen
 ├── Edit   → Story Edit Screen
 └── View   → Story View Screen
```

Ví dụ phân tách trách nhiệm cho `Bug`:

```text
Field Configuration (F02):         Screen (F03) "Bug Create Screen":
  Priority     required             ┌──────────────────────────────┐
  Assignee     optional             │ Details                      │
  Environment  required             │ Subject, Description,        │
                                    │ Environment, Priority        │
                                    ├──────────────────────────────┤
                                    │ Assignment                   │
                                    │ Assignee                     │
                                    └──────────────────────────────┘
```

Kiến trúc tổng thể:

```text
Project ─► Issue Type Scheme (F01) ─► available types
                                         │
                              OpenProject Work Package
                           ┌─────────────┴─────────────┐
                    Field Configuration (F02)     Screen Scheme (F03)
                    required/hidden/read-only/    create / edit / view /
                    default                        transition
```

## 6. Yêu cầu chức năng

Ký hiệu: FR = functional requirement. Mỗi FR phải có test tương ứng.

### 6.1 Screen và Section

* **FR-01** Tạo/sửa/xem/liệt kê Screen với `name` (duy nhất), `description`, `screen_type` ∈ {`create`, `edit`, `view`, `transition`}, `active`.
* **FR-02** Mỗi Screen có danh sách Section có thứ tự (`position`), mỗi Section có `name`. Thêm/sửa/xoá/sắp xếp Section.
* **FR-03** Ví dụ Section: `General`, `Description`, `Assignment`, `Planning`.

### 6.2 Item (đặt field)

* **FR-04** Thêm/sửa/xoá Item trong Section với `field_key`, `position`, `width`, `visible`.
* **FR-05** `field_key` dùng cùng abstraction với Feature 02; **không** tạo model Field. Giá trị hợp lệ gồm attribute native và `custom_field_<id>`.
* **FR-06** Một `field_key` chỉ xuất hiện **một lần** trên một Screen.
* **FR-07** Di chuyển Item giữa Section và đổi thứ tự (kéo-thả ở UI; có phương án bàn phím và vẫn hoạt động khi tắt JS bằng ô số, theo F01 §13.3).
* **FR-08** `visible = false` chỉ ẩn **vị trí** trên screen; nó **không** thay `hidden` của Field Configuration và không bao giờ làm hiện field mà F02/native ẩn.
* **FR-09** `width` là gợi ý bố cục cho frontend (giá trị: `full`, `half`; mặc định `full`).

### 6.3 Screen Scheme

* **FR-10** CRUD Screen Scheme với `name` (duy nhất), `description`, `active`.
* **FR-11** Scheme có các dòng ánh xạ: `issue_type_id` (trỏ `Type` native) → `create_screen_id`, `edit_screen_id`, `view_screen_id`, `transition_screen_id` (đều tuỳ chọn). Mỗi Issue Type tối đa một dòng trong một scheme.
* **FR-12** Screen được gán vào ô nào phải đúng `screen_type` của ô đó.
* **FR-13** Một Screen có thể dùng ở nhiều dòng/scheme; UI hiển thị "Used by".

### 6.4 Gán cho Project

* **FR-14** Gán một Screen Scheme cho Project (`project_screen_schemes`); mỗi project tối đa một scheme.
* **FR-15** Project không có scheme ⇒ dùng layout native (`source = native`).

### 6.5 Resolver

* **FR-16** `ScreenResolver.for(project:, issue_type:, context:)` trả kết quả mô tả ở mục 8.
* **FR-17** Context hợp lệ: `:create`, `:edit`, `:view`, `:transition`. Context khác ⇒ lỗi.
* **FR-18** Resolver áp quy tắc xung đột (mục 9): bỏ field không tồn tại/không khả dụng, loại field `hidden`.
* **FR-19** Cache theo request cho `(project, type, context)`; không truy vấn trong vòng lặp từng work package.
* **FR-20** Fail-open: lỗi nội bộ không được làm hỏng tạo/sửa/xem work package; ghi log và trả `source = native`.

### 6.6 Transition Screen (chỉ abstraction)

* **FR-21** Hỗ trợ `screen_type = transition`, ô `transition_screen_id`, và context `:transition` trong resolver/API để Feature Workflow sau này tiêu thụ.
* **FR-22** **Không** có logic chuyển trạng thái, validator, hay hành vi nào gắn với transition trong feature này.

### 6.7 Xác thực xung đột với Field Configuration

* **FR-23** Khi lưu cấu hình, kiểm tra theo mục 9; cấu hình mâu thuẫn bị từ chối với mã lỗi ổn định và thông điệp i18n.

### 6.8 Vòng đời

* **FR-24** Screen và Screen Scheme đang được dùng **không xoá được**; chỉ deactivate/activate (inactive = bị bỏ qua, project dùng native). Xoá Section/Item là sửa nội dung nên được phép.
* **FR-25** Sửa một Screen/Scheme đang dùng ở ≥1 nơi qua bước xác nhận nêu số scheme/project/type bị ảnh hưởng.

## 7. Domain model

Tiền tố `screen_*`; không có "jira" ở bất kỳ đâu.

```text
screens
  id, name (unique, ≤255), description, screen_type enum
  {create, edit, view, transition}, active, created_at, updated_at

screen_sections
  id, screen_id FK, name, position, created_at, updated_at
  UNIQUE(screen_id, name)

screen_items
  id, screen_id FK, section_id FK, field_key, position,
  width enum {full, half} default full, visible bool default true,
  created_at, updated_at
  UNIQUE(screen_id, field_key)

screen_schemes
  id, name (unique, ≤255), description, active, created_at, updated_at

screen_scheme_items
  id, screen_scheme_id FK, issue_type_id FK -> types,
  create_screen_id FK null, edit_screen_id FK null,
  view_screen_id FK null, transition_screen_id FK null
  UNIQUE(screen_scheme_id, issue_type_id)

project_screen_schemes
  id, project_id FK UNIQUE, screen_scheme_id FK, created_at, updated_at
```

Quy tắc:

* `field_key` không có FK; validate bằng registry `Screens::Fields` (attribute native đã biết + `custom_field_<id>` của một `WorkPackageCustomField` tồn tại).
* `issue_type_id` trỏ `types` native.
* FK từ scheme item/project tới screen/scheme **không** cascade xoá; model chặn `destroy` khi đang được dùng.
* Xoá Section ⇒ xoá các Item của nó; xoá Type native cascade `screen_scheme_items`.
* Migration có thể đảo ngược; không thêm cột vào bảng core.

## 8. Resolver — hợp đồng

```ruby
ScreenResolver.for(project: project, issue_type: type, context: :create)
```

Kết quả:

```json
{
  "source": "screen",
  "screen":  { "id": 12, "name": "Bug Create Screen", "context": "create" },
  "sections": [
    {
      "id": 1, "name": "General", "position": 1,
      "fields": [
        { "key": "subject",  "position": 1, "width": "full" },
        { "key": "priority", "position": 2, "width": "half" }
      ]
    },
    {
      "id": 2, "name": "Assignment", "position": 2,
      "fields": [
        { "key": "assignee", "position": 1, "width": "half" },
        { "key": "watchers", "position": 2, "width": "half" }
      ]
    }
  ]
}
```

* `source ∈ {screen, native}`. Khi `native`: `screen` và `sections` rỗng; bên tiêu thụ dùng layout native.
* Sections và fields sắp theo `position`; field `visible = false` hoặc bị F02 `hidden` không có trong `fields`.
* **[Quyết định mở Q-A]** Có đính kèm trạng thái field hiệu lực (từ F02) vào từng field không? Mặc định: **có** (`required`, `readOnly`, `default`, `source`) để frontend chỉ gọi một API; nếu module F02 tắt thì bỏ phần này.
* **[Quyết định mở Q-B]** Fallback khi ngữ cảnh chưa gán screen. Mặc định: `view → edit → native`; `edit → native`; `create → native`; `transition → native`.

Luồng nội bộ:

```text
Project → ProjectScreenScheme (active?) → ScreenSchemeItem(type)
        → Screen cho context (active?) → Sections/Items
        → lọc field không tồn tại/không khả dụng → áp Field Configuration (hidden/required/read-only)
        → kết quả
```

## 9. Xung đột với Field Configuration

Không để hai cấu hình tự mâu thuẫn. Thứ tự đánh giá:

```text
Screen → field tồn tại? → Field Configuration → visible? → required? → read-only?
```

Quy tắc:

* `hidden` thắng vị trí trên screen: field hidden không hiển thị dù được đặt vào screen.
* `read-only` thắng UI chỉnh sửa: field vẫn hiển thị nhưng không sửa được.
* `required = true` **và** `visible/hidden` mâu thuẫn ⇒ **cấu hình không hợp lệ và phải bị từ chối khi lưu** (theo Feature 02: `hidden_and_required`).
* Field `required` (và không có default) không có trên Screen `create` của type ⇒ không thể tạo work package ⇒ **từ chối khi lưu** gán screen đó cho type (mã `required_not_placed`). **[Quyết định mở Q-C]** mặc định: từ chối; có thể đổi thành cảnh báo.
* Field `hidden` được đặt lên screen ⇒ **cảnh báo** khi lưu (rule có thể đổi sau), loại ở runtime.
* Field không còn khả dụng ở project/type (custom field bị tắt…) ⇒ bỏ qua ở runtime, cảnh báo trong editor ("không khả dụng trong N project").
* Screen không bao giờ thay `required`/`read-only`/`default`.
* Screen **không phải ranh giới enforcement**: API/import vẫn tạo/sửa work package bất kể screen; chặn là việc của F02/native.
* Resolver trả thêm `diagnostics` (`unavailable`, `hidden_but_placed`, `required_not_placed`) để UI/QA phát hiện.

## 10. Quan hệ với native OpenProject

Hai chế độ:

* **Mode A — Native:** Screen config là abstraction/API; **V1 không ghi vào** `FormConfiguration` native và không sửa Angular native. Layout native vẫn là mặc định khi không có screen.
* **Mode B — External UI (mode ưu tiên):**

  ```text
  Frontend riêng (Vue/React)
        ↓
  Screen Resolver ──► Field Configuration Resolver
        ↓
  OpenProject API / schema → Work Package
  ```

  Screen metadata là nguồn layout cho frontend riêng; frontend chỉ render metadata. Plugin **MUST NOT** tự xây lại toàn bộ Work Package form; luôn đi qua OpenProject API/schema.

**[Quyết định mở Q-D]** Có "đẩy" Screen xuống form native hay không? Mặc định: **không** (tránh ghi đè cấu hình native của admin, tránh hai nguồn sự thật). Nếu cần, làm feature riêng.

## 11. REST API (API v3, HAL)

Không dùng `/api/jira/...`. Mapping từ mô tả ý tưởng sang quy ước repo:

```http
# Screens
GET    /api/v3/screens
GET    /api/v3/screens/:id
POST   /api/v3/screens                      # admin
PATCH  /api/v3/screens/:id                  # admin
POST   /api/v3/screens/:id/activate         # admin
POST   /api/v3/screens/:id/deactivate       # admin

# Sections
POST   /api/v3/screens/:id/sections
PATCH  /api/v3/screens/:id/sections/:section_id
DELETE /api/v3/screens/:id/sections/:section_id

# Items (field placement)
POST   /api/v3/screens/:id/items
PATCH  /api/v3/screens/:id/items/:item_id
DELETE /api/v3/screens/:id/items/:item_id

# Screen schemes
GET    /api/v3/screen_schemes
POST   /api/v3/screen_schemes
PATCH  /api/v3/screen_schemes/:id
POST   /api/v3/screen_schemes/:id/activate | deactivate

# Project
PUT    /api/v3/projects/:project_id/screen_scheme       # permission assign_screen_scheme

# Resolver — kênh chính cho frontend
GET    /api/v3/projects/:project_id/types/:type_id/screens/:context
       # context ∈ create | edit | view | transition
```

* **Không có `DELETE` cho Screen và Screen Scheme** (FR-24); Section/Item có `DELETE`.
* Lỗi theo cấu trúc chuẩn API v3; mã ổn định: `unknown_field`, `duplicate_field`, `context_mismatch`, `hidden_and_required`, `required_not_placed`, `in_use`, `invalid_context`.
* Context sai ⇒ 422. `PUT .../screen_scheme` với scheme không tồn tại/inactive ⇒ 422.
* Response resolver theo mục 8, bọc HAL (`_links`).

## 12. UI quản trị

Vị trí menu: **Administration → Work packages → Screens** (cùng khu vực F01/F02; nhãn qua i18n).

* **Danh sách Screen:** cột Name, Type (context), Used by, Status. Hành động: Create, Edit, Clone, Deactivate (không có Delete).
* **Editor Screen:** danh sách Section; trong mỗi Section là danh sách Item (tên field, menu thao tác ⋮, width, visible). Nút `+ Add section`. Kéo-thả theo chuỗi `field → section → position`, kèm nút Lên/Xuống (Alt+↑/↓) và vùng `aria-live`; hoạt động khi tắt JS bằng ô số.
  ```text
  ┌──────────────────────────────────────────┐
  │ Bug Create Screen                        │
  │ General                                  │
  │  Subject      ⋮                          │
  │  Priority     ⋮                          │
  │  Component    ⋮                          │
  │ Assignment                               │
  │  Assignee     ⋮                          │
  │  Watchers     ⋮                          │
  │            + Add section                 │
  └──────────────────────────────────────────┘
  ```
* **Screen Schemes:** bảng Issue Type × (Create / Edit / View / Transition) chọn screen bằng dropdown; hiển thị cảnh báo/lỗi xung đột (mục 9) ngay trong bảng.
* **Project Settings → Work packages → Screen scheme:** dropdown scheme, xem trước layout theo (type, context) và nguồn hiệu lực `screen`/`native`.
* Dùng Primer/ViewComponent + Turbo + Stimulus như F01/F02; không thêm Angular mới.

## 13. Phân quyền

| Hành động | Quyền |
|---|---|
| Quản lý Screen / Section / Item / Scheme | Admin |
| Gán Screen Scheme cho project | `assign_screen_scheme` (project permission, admin cấp cho role) |
| Đọc layout đã resolve | `view_work_packages` của project |

## 14. Yêu cầu phi chức năng

* **Hiệu năng:** resolve không phát sinh N+1; preload theo lô khi cần cho danh sách.
* **An toàn:** fail-open (FR-20); boot guard cho mọi điểm chạm core (nếu có).
* **i18n:** mọi chuỗi giao diện/thông điệp lỗi dùng i18n; không hard-code.
* **Khả dụng:** kéo-thả có phương án bàn phím; hoạt động khi tắt JS.
* **Nhất quán dữ liệu:** thao tác nhiều bước (lưu screen cùng section/item) trong một transaction.
* **Tương thích ngược:** project không cấu hình gì ⇒ hành vi native không đổi.

## 15. Edge cases agent phải xử lý

* Screen rỗng (không Section/Item) vẫn hợp lệ nhưng cảnh báo khi gán cho context `create`.
* Section rỗng được phép.
* Xoá Section chứa Item ⇒ Item bị xoá theo.
* Custom field bị tắt/xoá sau khi đã đặt lên screen.
* Type bị xoá ⇒ `screen_scheme_items` cascade.
* Deactivate Screen đang được scheme dùng ⇒ ô đó chuyển về fallback (Q-B).
* Deactivate Screen Scheme đang gán cho project ⇒ project dùng native.
* Hai request đồng thời đổi thứ tự cùng một Screen.
* Field key trùng trên cùng Screen.
* Gán Screen sai `screen_type` vào ô.

## 16. Tiêu chí chấp nhận (Acceptance)

Feature hoàn thành khi **tất cả** đạt:

- [ ] Create / Edit / View Screen hoạt động
- [ ] Transition Screen có abstraction (type, ô scheme, context resolver), không có logic workflow
- [ ] Screen CRUD (không xoá khi đang dùng; deactivate/activate)
- [ ] Section CRUD và sắp xếp
- [ ] Field placement và field ordering (kéo-thả + bàn phím + không JS)
- [ ] Screen Scheme (Issue Type → screens theo context)
- [ ] Project → Screen Scheme mapping
- [ ] Resolver + REST API resolver endpoint (cache theo request, fail-open, `diagnostics`)
- [ ] Conflict validation với Field Configuration (mục 9), mã lỗi ổn định
- [ ] REST API đầy đủ theo mục 11, có tài liệu OpenAPI
- [ ] Permission (`assign_screen_scheme`, admin) và test 403
- [ ] Migration đảo ngược được
- [ ] Automated tests: model, service, resolver, request spec API, feature spec admin UI (gồm bàn phím)
- [ ] Không tạo duplicate Work Package / Field model
- [ ] Không modify OpenProject core domain model; không thêm cột vào bảng core
- [ ] Không có chuỗi "jira" trong tên bảng/class/route/permission/menu/i18n
- [ ] Module vẫn chạy khi Feature 02 tắt (resolver bỏ phần trạng thái field)

## 17. Kịch bản kiểm thử tối thiểu (gợi ý cho agent)

1. Project chưa gán scheme → resolver trả `source = native`.
2. Gán scheme, type `Bug`, context `create` → trả đúng sections/fields theo thứ tự.
3. Field `hidden` (F02) đặt trên screen → không có trong `fields`, có trong `diagnostics.hidden_but_placed`.
4. Field `required` không có trên Screen `create` → lưu gán bị từ chối `required_not_placed` (Q-C mặc định).
5. Screen `edit` gán vào ô `create_screen_id` → `context_mismatch`.
6. Hai Item cùng `field_key` trên một screen → `duplicate_field`.
7. Context `foo` → 422 `invalid_context`.
8. Xoá Screen đang dùng → bị chặn (`in_use`); deactivate → project dùng fallback.
9. Lỗi giả lập trong resolver → work package vẫn tạo/sửa được; log được ghi.
10. User không có quyền → 403 trên PUT project scheme và API admin.

## 18. Lộ trình triển khai đề xuất

```text
01 Issue Type Scheme → 02 Field Configuration → 03 Screen & Layout → 04 Jira-style Issue View → 05 Issue Navigator
```

Cắt lát:

* **Slice 1:** model + migration + `Screens::Fields` + Resolver + API đọc.
* **Slice 2:** CRUD API + admin UI Screen/Section/Item (kéo-thả).
* **Slice 3:** Screen Scheme + gán project + xác thực xung đột + cảnh báo tác động + xem trước.

Feature tiếp theo: **Idea 04 — Issue View** (bố cục chi tiết issue, tabs/sections, activity, links, hierarchy), tiêu thụ trực tiếp resolver của feature này.

## 19. Đầu ra mong đợi từ agent

1. Spec: `docs/superpowers/specs/<ngày>-screens-design.md` (có bảng đối chiếu code, quyết định, rủi ro, câu hỏi mở đã chọn mặc định).
2. Plan: danh sách task có thứ tự, mỗi task có tiêu chí hoàn thành và test.
3. Implementation trong `modules/screens` + test, rubocop/erb_lint sạch, không đụng file core.
