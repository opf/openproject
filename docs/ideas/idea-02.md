# Feature 02 — Issue Field Configuration

Feature 01 đã tạo lớp Issue Type Scheme. Feature 02 tận dụng nó để giải quyết một khác biệt quan trọng với Jira: field configuration theo từng Issue Type.

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

---

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

---

## 21. Permission

Tạo:

```text
Manage Field Configurations
Assign Field Configuration Scheme
```

Không nên cho Project Manager tùy ý thay đổi global configuration nếu họ chỉ có project-level permission.

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
