# Feature 02 — Issue Field Configuration

Feature 01 đã tạo lớp Issue Type Scheme. Feature 02 tận dụng nó để giải quyết một khác biệt quan trọng với Jira: field configuration theo từng Issue Type.

## 0. Review & Revision (2026-10-03)

Phần này là kết quả đối chiếu idea với code thật của repo (branch `feature/type-schemes`, Rails 8.1) và Feature 01 đã triển khai. Các khối `> **Revised:**` ở các mục sau sửa hoặc làm rõ nội dung gốc; phần gốc được giữ nguyên để truy vết.

### 0.1 Phát hiện đã kiểm chứng trong code

| # | Phát hiện | Bằng chứng | Hệ quả cho idea |
|---|---|---|---|
| R1 | **Per-Type form configuration đã tồn tại và còn chi tiết hơn Jira ở một điểm**: repo đã tách `Type` thành `TypeVariant`; mỗi project dùng một variant cho mỗi type (`ProjectType#variant`). Variant chứa form groups, `required_attributes`, mô tả mặc định và patterns. | `app/models/type_variant.rb`, `app/models/form_configuration.rb`, `app/models/type_variant/configuration_linkable.rb`, `app/models/project_type.rb` | Granularity "Project × Type" đã có sẵn. Feature 02 không được tạo lớp song song cho cùng thứ; chỉ bổ sung phần còn thiếu (xem R2–R6) và phải xác định thứ tự ưu tiên với lớp native. |
| R2 | **Hidden đã có nghĩa native**: attribute không nằm trong group nào của form configuration thì không hiện trong form. Ngoài ra có extension point chính thức `Type.add_constraint(attribute, callable)` / `passes_attribute_constraint?(attr, project:)` để plugin ẩn attribute theo type/project (Backlogs dùng cho `story_points`, `position`). | `app/models/type/attributes.rb:55-68,196-210`; `modules/backlogs/.../patches/api/work_package_schema_representer.rb:87` | "Visible" của Feature 02 **không thể ép một field hiện ra** nếu form configuration không đặt nó vào layout (đó là phạm vi Feature 03). Feature 02 chỉ có thể **trừ bớt** (Hidden) trên tập field mà native đã cho hiện. Hidden nên hook qua `add_constraint`, không prepend. Lưu ý mỗi attribute chỉ giữ **một** callable; phải bọc (chain) constraint có sẵn, không ghi đè của Backlogs/Costs. |
| R3 | **Required đã có nhưng chỉ cho custom field**: `required_attributes` của variant chỉ bật/tắt được cho custom field (service từ chối khác với `not_a_custom_field`); enforcement qua `WorkPackage#custom_field_required?` → `CustomValue#validate_presence_of_required_value`; schema API lấy từ `custom_field_required?`. **Native field (description, assignee, priority, due date…) không có "required theo type"**. | `app/models/work_package.rb:613-623`, `app/models/custom_value.rb:105-118`, `app/services/work_package_types/form_configuration_rows/toggle_required_service.rb`, `lib/api/v3/work_packages/schema/base_work_package_schema.rb:48` | Khoảng trống thật của Feature 02 là **required cho native field** (và cho custom field theo scheme, hợp nhất với `required_attributes`). Cần enforce ở contract (server-side) và phản ánh `required` trong schema API để Angular hiện dấu `*`. Có tiền lệ module patch schema representer (Backlogs). |
| R4 | **Read-only theo type không tồn tại.** Chỉ có read-only theo Status (Enterprise `readonly_work_packages`), theo quyền, và field tự sinh. Contract có điểm hook sạch: `writable_attributes`; schema `writable` suy ra từ contract. | `app/contracts/work_packages/base_contract.rb:255-263,657-670`; `app/models/status.rb:79` | Read-only là giá trị gia tăng rõ nhất. Hook: prepend `writable_attributes` (module đã prepend `BaseContract` ở Feature 01, không thêm điểm chạm mới). Phải cùng enforce cả API lẫn UI nhờ schema. |
| R5 | **Default value theo type chỉ có `default_work_package_description` và subject patterns** (aspect `defaults` của variant); custom field có `default_value` toàn cục. Không có default cho field khác. | `app/models/type_variant.rb:40,92`, `app/services/work_package_types/copy_configuration/defaults_service.rb` | Default của Feature 02 áp cho field khác (priority, assignee, custom field…), hook vào `SetAttributesService` đã prepend ở Feature 01. Phải định nghĩa rõ quan hệ với `default_work_package_description` (native thắng cho description hay config thắng?). |
| R6 | **Tên trùng gây nhầm**: core đã có `FormConfiguration`, `FormConfigurationAttribute`, `FormConfigurationGroup`. Idea đặt `Field Configuration` và `field_configuration_items` — gần như trùng nghĩa/tên. | `app/models/form_configuration*.rb` | Đổi tên khái niệm mới thành **Field Rule Set** / **Field Rule** (xem 0.2). |
| R7 | **Feature 01 đã định hình các quy ước phải theo**: không dùng tiền tố/tên "jira" trong bảng, class, route, permission, menu; API đặt trong API v3 (HAL), không `/api/jira/...`; module `modules/*`; manage = admin, assign = project permission; mọi project luôn resolve được một scheme (fallback Default); không có thao tác xoá scheme (chỉ deactivate); hai prepend vào core đã có. | `docs/superpowers/specs/2026-10-02-type-scheme-design.md` §2, §13; `modules/type_schemes/lib/open_project/type_schemes/*` | Mọi tên `jira_*`, `/api/jira/...`, "Jira Configuration" trong idea phải đổi. Cần quyết định tương tự cho "luôn có scheme" và "xoá". |
| R8 | **Scheduling/hierarchy tự cập nhật work package** (ancestors, dates qua relations) bằng system user và contract; read-only/required áp dụng nguyên xi sẽ chặn các cập nhật hệ thống này. | `app/services/work_packages/update_ancestors*`, `set_schedule_service` (dùng `WorkPackages::UpdateService` với user hệ thống) | Cần quy tắc phạm vi: rule chỉ ràng buộc **người dùng thao tác (UI/API)**, không ràng buộc cập nhật phát sinh từ hệ thống. |
| R9 | **Thêm rule required cho work package đã tồn tại** có thể khiến mọi chỉnh sửa không liên quan (đổi status, kéo Gantt, bulk edit, import) đều lỗi vì field cũ đang trống. | Hành vi contract: validate toàn bộ model khi save | Cần chiến lược "grandfather": xem 0.3. |

### 0.2 Quyết định thiết kế đã sửa

1. **Tên khái niệm:** `Field Rule Set` (thay `Field Configuration`), `Field Rule` (thay `Field Configuration Item`), `Field Rule Scheme` (thay `Field Configuration Scheme`). Bảng: `field_rule_sets`, `field_rules`, `field_rule_schemes`, `field_rule_scheme_items`, `project_field_rule_schemes`. Class: `FieldRuleSet`, `FieldRule`, `FieldRuleScheme`, `FieldRuleSchemeItem`, `ProjectFieldRuleScheme`. Module: `modules/field_rules`. Không có "jira" ở bất kỳ đâu.
2. **Mô hình lớp (layer) và thứ tự ưu tiên** — đây là điểm idea gốc thiếu:

   ```text
   Layer 0  Native: form configuration của TypeVariant (field nào nằm trong form,
            required custom field, default description) + permission + status read-only
   Layer 1  Field Rule Set (Feature 02): chỉ SIẾT CHẶT hoặc bổ sung
            hidden ⊂ native-visible, required, read_only, default
   ```

   * Hidden (Layer 1) thắng visible (Layer 0). Visible (Layer 1) **không** làm hiện field mà Layer 0 không hiển thị.
   * Required = Layer 0 **OR** Layer 1 (rule không thể nới lỏng yêu cầu native/global; không có "bỏ required" của custom field global).
   * Read-only = Layer 0 **OR** Layer 1.
   * Default: giá trị người dùng nhập > default của Field Rule > native default (custom field default, description template).
3. **Ma trận hợp lệ của một rule** (validate khi lưu rule set, server-side):
   * `hidden` + `required` ⇒ **không hợp lệ** (trừ khi có default, khi đó field được điền ngầm; V1 chọn: không hợp lệ).
   * `required` + `read_only` ⇒ chỉ hợp lệ nếu có `default_value` (nếu không, không thể tạo work package).
   * `hidden` + `read_only` ⇒ dư thừa, chuẩn hoá thành `hidden`.
   * Các field **không cấu hình được** (cố định): `type`, `project`, `status` (trên create), `author`, các field tự sinh/derived, `id`. `subject` luôn visible, required, không read-only. Danh sách field cấu hình được là allowlist tường minh (xem 0.4), không phải mọi key.
   * Field `hidden`/`read_only` có `default_value` ⇒ default vẫn được áp khi **tạo** (hệ thống điền, người dùng không sửa được).
4. **Phạm vi áp dụng (enforcement scope):**
   * Rule ràng buộc **người dùng** (UI/API với user thật) khi tạo và sửa. Không ràng buộc cập nhật hệ thống (R8): scheduling, ancestors, import hệ thống, rake. Điều kiện nhận biết: user hiện tại là `User.system`/service context, hoặc cờ rõ ràng truyền vào contract.
   * Admin không tự động bypass (để kiểm thử được rule); bypass đặt sau Feature 14/15 nếu cần.
5. **Quy tắc grandfather (R9) — Required:**
   * **Create:** enforce required đầy đủ.
   * **Update:** chỉ báo lỗi required cho field nếu (a) field đang bị thay đổi/xoá trong lần lưu này, hoặc (b) type/project của work package đổi (rule set mới có hiệu lực). Work package cũ thiếu giá trị ở field mới-bắt-buộc **vẫn sửa được field khác**; form hiển thị cảnh báo "field này bắt buộc nhưng đang trống" thay vì chặn.
   * Admin có tuỳ chọn per rule: `enforce_on_update` (mặc định `false` ở V1 để an toàn).
6. **Hidden & dữ liệu:** Hidden chỉ ẩn khỏi form/schema và **chặn ghi** (`error_readonly`); dữ liệu hiện có **không bị xoá** và vẫn trả về trong GET API (để không phá tích hợp). Quyết định này phải ghi trong tài liệu API.
7. **Custom field:** rule không kích hoạt custom field trong project; custom field phải đang active ở project (native). Rule trên field không active bị bỏ qua và hiện cảnh báo ở trang cấu hình ("field không khả dụng trong N project").
8. **"Luôn có scheme" theo Feature 01:** để nhất quán, không bắt buộc gán. Project không có Field Rule Scheme ⇒ không có rule nào ⇒ hành vi native (Layer 0). Không tạo Default Field Rule Scheme tự động (rule rỗng không có ý nghĩa). Ngược với F01 vì F01 là allow-list bắt buộc, còn F02 chỉ là lớp siết.
9. **Không xoá:** theo F01, Rule Set và Rule Scheme **không xoá** khi đang được dùng; deactivate (inactive = không áp rule, project dùng native). Xoá rule *item* trong rule set được phép (đó là sửa nội dung).
10. **API:** API v3 (HAL) thay `/api/jira/...`:
    * `GET /api/v3/projects/{id}/types/{type_id}/field_rules` — rule đã resolve (kèm lớp native hợp nhất) cho project + type.
    * CRUD `/api/v3/field_rule_sets`, `/api/v3/field_rule_schemes` (ghi: admin). `PUT /api/v3/projects/{id}/field_rule_scheme` (permission assign).
    * Schema work package (`/api/v3/work_packages/schemas/...`) phản ánh `required`/`writable` theo rule — đây là kênh chính cho Angular.
11. **Validator dùng chung** `FieldRules::Validator` (idea §19) cung cấp cả chế độ "validate model" và "describe" (trả cấu hình hiệu lực) để Workflow/Automation dùng; trả mã lỗi ổn định (`required`, `read_only`, `hidden`) kèm i18n, không hard-code chuỗi "for Bug issues".
12. **Điểm chạm core (xác nhận mục 24):**
    * Hidden: `Type.add_constraint` (extension point chính thức, bọc constraint hiện có).
    * Read-only + required (native/custom) ở contract: `BaseContract` prepend đã có từ F01 (thêm `writable_attributes`, validation required).
    * Schema `required`: patch `WorkPackageSchemaRepresenter` theo tiền lệ Backlogs (prepend trong module, có boot guard như F01 `assert_patch_targets!`).
    * Default: `SetAttributesService` prepend đã có từ F01.
    * Không sửa file core; không thêm bảng/cột vào bảng core.

### 0.3 Rủi ro đã nhận diện

* **Chồng chéo với form configuration của core** (R1, R6): người dùng có hai nơi cấu hình "required" (variant form config cho custom field và Field Rule). Giải pháp: UI hiển thị nguồn của mỗi trạng thái ("bắt buộc bởi form configuration" / "bắt buộc bởi Field Rule Set X") và rule không nới lỏng Layer 0.
* **Vỡ tích hợp** (import, mail handler, API client, bulk edit, copy/move project) khi thêm required/read-only: dùng quy tắc grandfather (0.2.5), phạm vi system (0.2.4), thông báo lỗi trả về theo cấu trúc chuẩn của API v3.
* **Hiệu năng:** resolve cho mỗi work package trong danh sách, export, bulk, schema: cache theo (project, type) trong request như Resolver F01; batch preload; không truy vấn rule trong vòng lặp từng work package.
* **Phụ thuộc private API/representer của core:** boot guard + fail-open (lỗi trong resolver không được làm sập tạo/sửa work package; ghi log và rơi về Layer 0).
* **Xung đột `add_constraint`:** một attribute một callable (R2) — bắt buộc chain.
* **Xung đột với Workflow (§23):** resolver expose trạng thái hiệu lực để Feature 14 kiểm tra xung đột (field hidden nhưng transition yêu cầu required); Feature 02 không tự giải.

### 0.4 Danh sách field cấu hình được (V1, allowlist)

* Native: `description`, `assignee`, `responsible`, `priority`, `category`, `version` (target version), `start_date`, `due_date`, `estimated_time`, `parent`.
* Custom field: mọi `WorkPackageCustomField` đang active trong project (kể cả field do module khác thêm qua custom field).
* Field của module khác (Backlogs `story_points`, `position`; Costs): đưa vào qua cơ chế đăng ký allowlist của module, V1 chỉ cho phép hidden/read-only nếu chính module đó không tự chặn.

### 0.5 Phạm vi V1 sau review (gọn hơn)

1. Field Rule Set + Rule (hidden, required, read_only, default) cho allowlist 0.4.
2. Field Rule Scheme (type → rule set), gán cho project (permission), admin UI cấu hình (kéo-thả thứ tự **chỉ nếu** Feature 03 chưa có layout; thứ tự hiển thị thực sự do form configuration native, nên V1 **không** làm drag & drop thứ tự trong màn hình này — `position` của rule chỉ dùng để sắp xếp bảng cấu hình).
3. Enforcement: contract (required, read-only, hidden-write), default tại create, schema API phản ánh.
4. Resolver + Validator dùng chung, API v3, permission, migration, test.
5. Hoãn: inheritance (§22, giữ V1 phẳng), Bulk Edit UI (§20, chỉ để lại API `editable?`), giải xung đột Workflow.

> Ghi chú về drag & drop: idea gốc §11 yêu cầu kéo-thả thứ tự field. Review xác nhận thứ tự hiển thị trong form do `FormConfiguration` (core) / Feature 03 quyết định, nên kéo-thả ở đây chỉ gây hiểu nhầm là đổi thứ tự form. Giữ `position` để sắp xếp bảng cấu hình và chuyển yêu cầu kéo-thả form sang Feature 03.

---

## 1. Mục tiêu

Cho phép cấu hình:

Với một Project + Issue Type, field nào được hiển thị, field nào bắt buộc, field nào read-only, field nào có giá trị mặc định.

Ví dụ:

```text
Project: CRM
Issue Type: Bug

Summary        Required
Description    Required
Priority       Required
Assignee       Optional
Environment    Required
Sprint         Optional
Story Points   Hidden
```

Trong khi Story:

```text
Project: CRM
Issue Type: Story

Summary        Required
Description    Required
Priority       Required
Assignee       Optional
Environment    Hidden
Sprint         Optional
Story Points   Required
```

Đây chính là lớp configuration mà các feature Issue Screen, Issue View, Workflow và Automation phía sau sẽ sử dụng.


## 2. Trước khi xây: OpenProject đã có gì?

OpenProject đã có Custom Fields và khả năng cấu hình chúng theo project/type ở mức native.

Vì vậy không được xây lại Custom Field.

Plugin chỉ bổ sung một lớp:

```text
OpenProject Custom Fields
          +
OpenProject native fields
          ↓
Jira Field Configuration
```

Ví dụ native fields:

```text
Subject
Description
Status
Priority
Assignee
Author
Due Date
Start Date
```

và custom fields:

```text
Environment
Story Points
Acceptance Criteria
Customer
Release
```

Plugin quản lý behavior/configuration, không quản lý bản thân field data.

> **Revised:** OpenProject (repo này) còn có sẵn per-Type/Project form configuration (`TypeVariant`, `FormConfiguration`), required cho custom field theo variant, và default description. Native field và custom field không do plugin lưu dữ liệu; plugin chỉ thêm *rule*. Xem 0.1 R1–R5.

---

## 3. Jira-like abstraction

Ta tạo:

```text
Field Configuration
        │
        ├── Subject
        ├── Description
        ├── Priority
        ├── Assignee
        ├── Story Points
        └── Environment
```

và liên kết:

```text
Project
   +
Issue Type
   ↓
Field Configuration
```

Ví dụ:

```text
CRM + Bug
       ↓
Bug Field Configuration

CRM + Story
       ↓
Story Field Configuration
```

> **Revised:** đổi tên khái niệm để không trùng `FormConfiguration` của core: Field Configuration → **Field Rule Set**. Xem 0.2.1.

---

## 4. Có nên cấu hình riêng từng Project × Issue Type?

Không nên.

Nếu có 100 project:

```text
100 Projects
×
5 Issue Types
=
500 configurations
```

sẽ rất khó quản trị.

Nên có Field Configuration Scheme:

```text
Field Configuration Scheme
          │
          ├── Bug Configuration
          ├── Story Configuration
          ├── Task Configuration
          └── Epic Configuration
```

Sau đó:

```text
Project
   ↓
Field Configuration Scheme
   ↓
Issue Type
   ↓
Field Configuration
```

> **Revised:** đồng ý không cấu hình trực tiếp Project × Type. Lưu ý repo đã có `ProjectType#variant` cho cấu hình form theo project × type; Field Rule Scheme là lớp *gom và gán hàng loạt* các rule set, không thay thế variant.

---

## 5. Domain Model

Tôi đề xuất 3 abstraction chính.

```text
jira_field_configurations
jira_field_configuration_items
jira_project_field_config_schemes
```

và một bảng mapping:

```text
jira_field_config_scheme_items
```

### 5.1 Field Configuration

```text
jira_field_configurations

id
name
description
active
created_at
updated_at
```

Ví dụ:

```text
Bug Configuration
Story Configuration
Task Configuration
Epic Configuration
```

### 5.2 Field Configuration Item

```text
jira_field_configuration_items

id
field_configuration_id
field_key
visibility
required
read_only
default_value
position
created_at
updated_at
```

`field_key` không nên hard-code thành database FK vì field có thể là:

```text
native field
custom field
plugin field
```

Ví dụ:

```text
field_key = "subject"
field_key = "description"
field_key = "priority"
field_key = "custom_field_12"
```

> **Revised:** không dùng tiền tố `jira_`. Tên bảng/model theo 0.2.1: `field_rule_sets`, `field_rules` (thay `field_configuration_items`; thêm cột `enforce_on_update`), `field_rule_schemes`, `field_rule_scheme_items`, `project_field_rule_schemes`. Ràng buộc: unique `(field_rule_set_id, field_key)`, unique `(scheme_id, type_id)`, unique `project_id`; FK `type_id` → `types` (cascade), `project_id` → `projects` (cascade). `field_key` là chuỗi kiểm tra bằng allowlist ở tầng model (0.4), không FK (đồng ý với idea).

---

## 6. Field State

Mỗi field có thể có:

```text
VISIBLE
HIDDEN
READ_ONLY
```

và:

```text
required = true / false
```

Do đó:

```text
Field
 ├── visibility
 │     ├── visible
 │     └── hidden
 │
 ├── required
 │
 └── read_only
```

Ví dụ:

```text
Description
visibility = visible
required = true
read_only = false
```

> **Revised:** tổ hợp trạng thái phải thoả ma trận hợp lệ 0.2.3 (ví dụ `hidden`+`required` bị từ chối). `visible` không có nghĩa ép field hiện (0.2.2).

---

## 7. Field Configuration Scheme

```text
jira_field_config_schemes

id
name
description
active
created_at
updated_at
```

Mapping:

```text
jira_field_config_scheme_items

id
scheme_id
issue_type_id
field_configuration_id
```

Ví dụ:

```text
Software Development Field Scheme

Epic   → Epic Configuration
Story  → Story Configuration
Task   → Task Configuration
Bug    → Bug Configuration
```

---

## 8. Project Mapping

```text
jira_project_field_config_schemes

project_id
scheme_id
```

Ví dụ:

```text
CRM
 ↓
Software Development Field Scheme
```

Khi user tạo:

```text
CRM
 ↓
Bug
```

resolver:

```text
CRM
 ↓
Field Configuration Scheme
 ↓
Bug
 ↓
Bug Field Configuration
```

---

## 9. Resolution Algorithm

Đây sẽ là một service quan trọng:

```text
FieldConfigurationResolver
```

Input:

```text
project
issue_type
```

Output:

```text
FieldConfiguration
```

Logic:

```text
Project
   ↓
Project Field Configuration Scheme
   ↓
Issue Type
   ↓
Field Configuration
   ↓
Field Rules
```

API nội bộ:

```ruby
resolver.for(project, issue_type)
```

> **Revised:** `FieldRules::Resolver.for(project, type)` trả về cấu hình **hiệu lực** = Layer 0 (native) ⊕ Layer 1 (rule set) theo 0.2.2, cache theo (project, type) trong request, có thể gọi hàng loạt (`for_many`) để tránh N+1. Không có scheme/rule set/inactive ⇒ trả Layer 0.

---

## 10. UI — Administration

Thêm:

```text
Administration
 └── Jira Configuration
      └── Field Configurations
```

Danh sách:

```text
Field Configurations
┌─────────────────────────┬────────┬─────────┐
│ Name                    │ Types  │ Status  │
├─────────────────────────┼────────┼─────────┤
│ Bug Configuration       │ 3      │ Active  │
│ Story Configuration     │ 4      │ Active  │
│ Task Configuration      │ 5      │ Active  │
└─────────────────────────┴────────┴─────────┘
```

> **Revised:** menu `Administration → Work packages → Field rules` (không có nhóm "Jira Configuration"). Theo F01: không có nút Delete cho Rule Set/Scheme đang dùng, chỉ Deactivate/Activate/Clone; xác nhận khi sửa rule set dùng bởi nhiều project (số project và số work package bị ảnh hưởng).

---

## 11. UI — Configure Fields

Ví dụ:

```text
Bug Configuration

Field               Visible  Required  Read-only
─────────────────────────────────────────────────
Subject                ✓        ✓          -
Description            ✓        ✓          -
Status                 ✓        -          -
Priority               ✓        ✓          -
Assignee               ✓        -          -
Environment            ✓        ✓          -
Sprint                 ✓        -          -
Story Points           -        -          -
Due Date               ✓        -          -
```

Có drag & drop để thay đổi thứ tự.

> **Revised:** cột `Visible/Required/Read-only` kèm `Default` và chỉ báo nguồn (native / rule set). Bỏ drag & drop thứ tự field (0.5). Hiển thị cảnh báo cho field không khả dụng trong project.

---

## 12. Default Value

Ví dụ:

```text
Priority
Default = Medium
```

hoặc:

```text
Environment
Default = Production
```

Nhưng cần phân biệt:

```text
Configuration default
        ≠
OpenProject native default
```

Resolver phải có precedence rõ ràng:

```text
Explicit user value
       ↓
Automation/default rule
       ↓
Field Configuration default
       ↓
OpenProject native default
```

Feature 02 chỉ implement tầng Field Configuration; Automation sẽ xử lý sau.

> **Revised:** precedence: giá trị người dùng > default của Field Rule > native default (custom field default, `default_work_package_description`). Default chỉ áp khi **tạo**; không bao giờ ghi đè giá trị đã có ở work package hiện hữu. Với read-only/hidden có default: hệ thống điền lúc tạo.

---

## 13. Required Field

Nếu:

```text
Description = Required
```

khi Create/Edit:

```text
Description *
```

Nếu user submit:

```text
Description = empty
```

thì:

```text
Description is required for Bug issues.
```

Quan trọng: validation phải thực hiện server-side, không chỉ frontend.

Nếu chỉ validate frontend:

```text
UI → bypass
API → create invalid issue
```

Điều này sẽ phá configuration.

> **Revised:** thông báo lỗi dùng i18n chung ("%{field} is required for %{type} work packages"), không hard-code "Bug issues". Quy tắc grandfather khi sửa: 0.2.5. Phản ánh vào schema API `required` để UI hiện dấu `*`.

---

## 14. Read-only Field

Ví dụ:

```text
Story Points = Read Only
```

UI:

```text
Story Points
┌──────────────────┐
│ 13               │ 🔒
└──────────────────┘
```

API cũng phải enforce.

Không được chỉ disable HTML:

```html
disabled
```

vì user vẫn có thể gọi API trực tiếp.

> **Revised:** enforce bằng `writable_attributes` của contract (API và UI cùng nguồn), trả `error_readonly` chuẩn của API v3. Không áp cho cập nhật hệ thống (0.2.4). Read-only khi *tạo* chỉ hợp lệ nếu có default (0.2.3).

---

## 15. Hidden Field

Ví dụ:

```text
Environment = Hidden
```

Plugin phải:

* không render trong Create
* không render trong Edit
* không đưa vào field selector nếu user không có permission đặc biệt
* không cho update qua UI

Nhưng không xóa dữ liệu cũ.

> **Revised:** hook bằng `Type.add_constraint` (0.1 R2). Hidden = không render, không có trong schema, chặn ghi; dữ liệu cũ giữ nguyên và vẫn đọc được qua GET API (0.2.6). "Field selector" cho user có quyền đặc biệt: bỏ khỏi V1 (không có cơ chế tương ứng ở core).

---

## 16. Create Issue Flow

Khi user:

```text
Create Work Package
```

flow:

```text
Project
   ↓
Issue Type Scheme
   ↓
Selected Issue Type
   ↓
Field Configuration Resolver
   ↓
Field Rules
   ↓
Render form
```

Ví dụ:

```text
CRM
 ↓
Bug
 ↓
Bug Field Configuration
 ↓
Render:
   Subject *
   Description *
   Priority *
   Environment *
   Assignee
   Sprint
```

> **Revised:** luồng thực tế: `Project → Type Scheme (F01) → Type → FieldRules::Resolver (Layer 0 ⊕ Layer 1) → schema/form`. Angular nhận `required`/`writable` từ schema API nên không cần sửa frontend; default được áp bởi `SetAttributesService` khi tạo.

---

## 17. Edit Issue Flow

Không chỉ Create.

Khi Edit:

```text
Work Package
 ↓
Project
 ↓
Type
 ↓
Field Configuration
 ↓
Apply rules
```

Điểm này quan trọng vì admin có thể thay đổi configuration sau khi issue đã tồn tại.

> **Revised:** khi sửa, áp quy tắc grandfather (0.2.5): thiếu giá trị ở field mới-bắt-buộc chỉ báo lỗi khi field đó đang được thay đổi/xoá hoặc type/project đổi; ngoài ra hiển thị cảnh báo, không chặn.

---

## 18. API

### Resolve configuration

```http
GET /api/jira/projects/{projectId}/issue-types/{typeId}/field-configuration
```

Response:

```json
{
  "configuration": {
    "id": 12,
    "name": "Bug Configuration"
  },
  "fields": [
    {
      "key": "subject",
      "visibility": "visible",
      "required": true,
      "readOnly": false
    },
    {
      "key": "description",
      "visibility": "visible",
      "required": true,
      "readOnly": false
    },
    {
      "key": "priority",
      "visibility": "visible",
      "required": true,
      "readOnly": false
    }
  ]
}
```

> **Revised:** dùng API v3 (HAL), không `/api/jira/...` (0.2.10). Response dùng camelCase của API v3, kèm `source` (`native`/`rule_set`) cho mỗi trạng thái.

---

## 19. Validation API

Nên có một service dùng chung:

```text
FieldConfigurationValidator
```

Ví dụ:

```ruby
validator.validate(work_package)
```

Output:

```json
{
  "valid": false,
  "errors": [
    {
      "field": "description",
      "message": "Description is required for Bug issues."
    }
  ]
}
```

Feature 14 Workflow và Feature 15 Automation sau này có thể reuse validator này.

> **Revised:** `FieldRules::Validator` có hai chế độ (`validate(work_package)` và `describe(project, type)`), trả mã lỗi ổn định + i18n; bao gồm cờ ngữ cảnh `actor: :user | :system` (0.2.4).

---

## 20. Bulk Edit

Feature 02 không cần implement Bulk Edit.

Nhưng configuration phải được thiết kế để Feature 07 có thể sử dụng.

Ví dụ:

```text
Bulk Edit
   ↓
Field Configuration
   ↓
Is field editable?
   ↓
YES / NO
```

> **Revised:** V1 chỉ cung cấp `FieldRules::Resolver#editable?(project, type, field)` / `for_many`; không đổi Bulk Edit UI. Cảnh báo: bulk update đi qua contract nên read-only/required sẽ được enforce ngay cả khi UI bulk chưa biết rule.

---

## 21. Permission

Tạo:

```text
Manage Field Configurations
Assign Field Configuration Scheme
```

Không nên cho Project Manager tùy ý thay đổi global configuration nếu họ chỉ có project-level permission.

> **Revised:** theo F01: `manage_field_rules` = admin-only (menu Administration); `assign_field_rule_scheme` = project permission (`require: :member`), enforce server-side ở controller/API; xem danh sách rule hiệu lực: member có `view_work_packages`.

---

## 22. Configuration Inheritance

Nên hỗ trợ:

```text
Global Scheme
      ↓
Project Scheme
      ↓
Issue Type Configuration
```

Nhưng không nên làm inheritance quá sâu ở Feature 02.

V1 chỉ cần:

```text
Project
 ↓
Field Configuration Scheme
 ↓
Issue Type
 ↓
Field Configuration
```

Đơn giản và dễ maintain.

> **Revised:** giữ V1 phẳng. Layer 0 (native) → Layer 1 (rule set) đã là hai lớp chồng; thêm Global Scheme mặc định là việc của phiên bản sau.

---

## 23. Configuration Conflict

Ví dụ:

```text
Field Configuration:
Priority = Hidden
```

nhưng Workflow yêu cầu:

```text
Transition → Resolve
Priority = Required
```

Đây là conflict.

Feature 02 chưa cần giải quyết toàn bộ workflow interaction, nhưng resolver phải expose trạng thái configuration để Feature 14 có thể kiểm tra.

> **Revised:** resolver expose `conflicts_with(requirements)` (vd. workflow yêu cầu field đang hidden) trả danh sách xung đột cho Feature 14; Feature 02 không chặn thao tác.

---

## 24. Core Modification

Mục tiêu:

```text
Core modifications = 0
```

Không sửa:

```text
WorkPackage
CustomField
Type
Project
```

Plugin chỉ xây:

```text
Configuration Layer
        ↓
OpenProject native fields
```

Điểm cần kiểm tra implementation thực tế là hook vào Create/Edit Work Package form và server-side validation.

Nếu OpenProject không cung cấp extension point phù hợp ở version CE đang dùng, phải tìm cách extension ít invasive nhất trước khi dùng decorator/prepend.

> **Revised:** điểm chạm đã xác định cụ thể ở 0.2.12; ưu tiên extension point chính thức (`add_constraint`) rồi tới prepend trong module (đã có tiền lệ F01 và Backlogs). Phải có boot guard, fail-open và spec bảo vệ như F01.

---

## 25. Ví dụ hoàn chỉnh

Giả sử:

```text
Project = CRM
Issue Type = Bug
```

Scheme:

```text
CRM
 ↓
Software Development Scheme
 ↓
Bug
 ↓
Bug Configuration
```

Configuration:

```text
Subject        Visible   Required
Description    Visible   Required
Status         Visible   No
Priority       Visible   Required
Assignee       Visible   No
Environment    Visible   Required
Sprint         Visible   No
Story Points   Hidden
```

Form:

```text
┌──────────────────────────────────────┐
│ Create Bug                           │
├──────────────────────────────────────┤
│ Summary *                            │
│ [________________________________]   │
│                                      │
│ Description *                        │
│ [________________________________]   │
│                                      │
│ Priority *                           │
│ [High ▼]                             │
│                                      │
│ Environment *                        │
│ [Production ▼]                       │
│                                      │
│ Assignee                             │
│ [Select... ▼]                        │
│                                      │
│ Sprint                               │
│ [Sprint 24 ▼]                        │
│                                      │
│             [Cancel] [Create]        │
└──────────────────────────────────────┘
```

> **Revised:** ví dụ `Story Points = Hidden` chỉ ẩn được nếu field đang hiện ở Layer 0; `Environment` (custom field) phải active trong project CRM. Sprint/Story Points thuộc module Backlogs: chỉ cấu hình được khi module đăng ký allowlist (0.4).

---

## 26. Acceptance Criteria

Feature 02 hoàn thành khi:

* [ ] Có Field Configuration.
* [ ] Có Field Configuration Scheme.
* [ ] Scheme có thể gán cho Project.
* [ ] Configuration gắn với Issue Type.
* [ ] Có thể cấu hình native field.
* [ ] Có thể cấu hình custom field.
* [ ] Field hỗ trợ Visible/Hidden.
* [ ] Field hỗ trợ Required/Optional.
* [ ] Field hỗ trợ Read-only.
* [ ] Có default value cơ bản.
* [ ] Create form áp dụng configuration.
* [ ] Edit form áp dụng configuration.
* [ ] Server-side validation hoạt động.
* [ ] API cũng bị enforce rule.
* [ ] Existing data không bị mất khi field bị hidden.
* [ ] Có REST API.
* [ ] Có permission.
* [ ] Có migration.
* [ ] Có unit/integration tests.
* [ ] Không thay đổi OpenProject core domain model.

> **Revised:** thay/bổ sung các tiêu chí sau (đánh dấu theo kiểm chứng được):
>
> * [ ] Tên khái niệm/bảng/route/permission không chứa "jira"; API trong API v3.
> * [ ] Ma trận hợp lệ 0.2.3 được enforce khi lưu rule set (có test từng tổ hợp).
> * [ ] Layer 1 không nới lỏng Layer 0 (required/read-only native vẫn giữ) và hidden thắng visible.
> * [ ] Required native field (vd. description) bị chặn ở Create qua UI **và** API; schema API trả `required: true`.
> * [ ] Update work package cũ thiếu giá trị ở field mới-bắt-buộc vẫn sửa được field khác (grandfather); đổi type kích hoạt kiểm tra.
> * [ ] Read-only chặn ghi qua API (`error_readonly`) và schema `writable: false`; cập nhật hệ thống (scheduling/ancestors) không bị chặn.
> * [ ] Hidden chặn ghi, không xoá dữ liệu, GET API vẫn trả giá trị cũ.
> * [ ] Default chỉ áp khi tạo, không ghi đè giá trị có sẵn; precedence 0.2.2 có test.
> * [ ] Không có scheme/inactive ⇒ hành vi native, không lỗi.
> * [ ] Rule Set/Scheme không xoá được khi đang dùng; có Deactivate/Activate/Clone.
> * [ ] Resolver cache theo (project, type), không N+1 trong danh sách; lỗi resolver không chặn tạo/sửa work package (fail-open).
> * [ ] `add_constraint` hiện có (Backlogs/Costs) vẫn hoạt động khi module cài đặt (chain, không ghi đè).

---

## 27. Dependency

Sau Feature 01:

```text
Issue Type Scheme
       │
       ▼
Feature 02
Field Configuration
       │
       ├──────────────┐
       ▼              ▼
Feature 03        Feature 04
Screens           Issue View
       │              │
       └──────┬───────┘
              ▼
        Issue Navigator
```

Feature 02 thực chất tạo ra:

```text
"WHAT fields are available?"
"WHICH fields are required?"
"WHICH fields are editable?"
"WHICH fields are visible?"
```

Còn Feature 03 sẽ trả lời:

"Các field đó xuất hiện ở màn hình nào và theo layout nào?"

Đó là lý do tôi tách Field Configuration và Screen/Layout thành hai plugin riêng, thay vì gom thành một plugin lớn.

> **Revised:** Feature 03 (Screens) là nơi quyết định *thứ tự và layout* field, nên drag & drop thứ tự form thuộc Feature 03 (0.5). Feature 02 cung cấp *trạng thái* (hidden/required/read-only/default); thứ tự hiển thị vẫn đến từ `FormConfiguration` native cho tới khi Feature 03 thay thế.
