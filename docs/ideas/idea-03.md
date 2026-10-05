## Idea 03 — Issue Screen & Layout

Tôi kiểm tra lại OpenProject hiện tại trước khi đưa feature này vào roadmap. Có một điểm **rất quan trọng**: OpenProject đã có **Form configuration** cho Work Package Type, cho phép thêm/bớt/sắp xếp attribute; ở Enterprise còn có section và related work package table. ([OpenProject.org](https://www.openproject.org/docs/system-admin-guide/manage-work-packages/work-package-types/form-configuration/?utm_source=chatgpt.com))

Vì vậy, **không nên làm một plugin “form layout” đơn thuần để copy chức năng native**.

### 1. Gap thực sự so với Jira

Jira có khái niệm:

> **Screen → Screen Scheme → Issue Type Screen Scheme**

Tức là layout của issue không chỉ phụ thuộc vào Issue Type, mà có thể quyết định **screen nào được dùng trong từng context**.

Trong khi OpenProject hiện tại chủ yếu cấu hình form theo **Work Package Type**. Schema API cũng phản ánh rằng form configuration tạo ra schema theo tổ hợp **Project + Type**. ([OpenProject.org](https://www.openproject.org/docs/development/concepts/resource-schemas/?utm_source=chatgpt.com))

Do đó Feature 03 nên tập trung vào:

> **Tạo abstraction Screen/Scheme phía trên Form Configuration native**, không thay thế Form Configuration của OpenProject.

---



# 03. Issue Screen & Layout



### Mục tiêu

Cho phép định nghĩa:

```text
Project
   ↓
Issue Type Scheme
   ↓
Screen Scheme
   ↓
Issue Type
   ↓
Create Screen
Edit Screen
View Screen
Transition Screen
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

Điểm quan trọng là **Screen không sở hữu dữ liệu field**.

Nó chỉ quyết định:

- field nào xuất hiện
- xuất hiện ở đâu
- thứ tự
- section nào
- screen nào sử dụng field

Còn:

- required
- hidden
- read-only
- default

vẫn thuộc **Feature 02 – Field Configuration**.

---



# 2. Phân biệt Feature 02 và 03

Đây là boundary rất quan trọng để tránh thiết kế chồng chéo.


| Feature             | Trả lời câu hỏi                               |
| ------------------- | --------------------------------------------- |
| Issue Type Scheme   | Issue Type nào được phép dùng?                |
| Field Configuration | Field có visible/required/read-only không?    |
| **Screen & Layout** | Field nằm ở đâu và xuất hiện trên screen nào? |
| Workflow            | Issue chuyển trạng thái thế nào?              |
| Screen Scheme       | Với context này dùng screen nào?              |


Ví dụ:

```text
Bug
```

Field Configuration:

```text
Priority      required
Assignee      optional
Environment   required
```

Screen:

```text
┌──────────────────────────────┐
│ Details                      │
│ Subject                      │
│ Description                  │
│ Environment                  │
│ Priority                     │
├──────────────────────────────┤
│ Assignment                   │
│ Assignee                     │
└──────────────────────────────┘
```

**Configuration ≠ Layout.**

---



# 3. Domain model

Tôi đề xuất 4 nhóm entity.

### `jira_screens`

```text
id
name
description
screen_type
active
created_at
updated_at
```

`screen_type`:

```text
CREATE
EDIT
VIEW
TRANSITION
```

Ví dụ:

```text
Bug Create Screen
Bug Edit Screen
Bug View Screen
Bug Resolve Screen
```

---



### `jira_screen_sections`

```text
id
screen_id
name
position
created_at
updated_at
```

Ví dụ:

```text
Bug Create Screen

01 General
02 Description
03 Assignment
04 Planning
```

---



### `jira_screen_items`

```text
id
screen_id
section_id
field_key
position
width
visible
created_at
updated_at
```

`field_key` tiếp tục dùng abstraction của Feature 02:

```text
subject
description
status
priority
assignee
due_date
custom_field_12
custom_field_25
```

Không tạo:

```text
JiraField
```

---



### `jira_screen_schemes`

```text
id
name
description
active
created_at
updated_at
```

---



### `jira_screen_scheme_items`

```text
id
screen_scheme_id
issue_type_id
create_screen_id
edit_screen_id
view_screen_id
transition_screen_id
```

Trong đó `issue_type_id` trỏ tới **native OpenProject Type** hoặc resolver từ Feature 01.

---



### Project mapping

```text
jira_project_screen_schemes

id
project_id
screen_scheme_id
created_at
updated_at
```

---



# 4. Kiến trúc tổng thể

Sau Feature 01–03 sẽ hình thành:

```text
                    ┌─────────────────────┐
                    │      Project        │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ Issue Type Scheme   │
                    └──────────┬──────────┘
                               │
                       available types
                               │
                    ┌──────────▼──────────┐
                    │    OpenProject      │
                    │     Work Package    │
                    └──────────┬──────────┘
                               │
                 ┌─────────────┴─────────────┐
                 │                           │
        ┌────────▼────────┐       ┌─────────▼─────────┐
        │Field Config     │       │  Screen Scheme    │
        │                 │       │                   │
        │required         │       │Create             │
        │readonly         │       │Edit               │
        │hidden           │       │View               │
        │default          │       │Transition         │
        └─────────────────┘       └───────────────────┘
```

Đây là kiến trúc đúng hướng để sau này xây Jira-like UI.

---



# 5. Resolver

Nên tạo service ngay từ đầu:

```ruby
ScreenResolver
```

API conceptual:

```ruby
resolver.for(
  project: project,
  issue_type: type,
  context: :create
)
```

Kết quả:

```json
{
  "screen": {
    "id": 12,
    "name": "Bug Create Screen"
  },
  "sections": [
    {
      "name": "General",
      "position": 1,
      "fields": [
        "subject",
        "priority"
      ]
    },
    {
      "name": "Assignment",
      "position": 2,
      "fields": [
        "assignee",
        "watchers"
      ]
    }
  ]
}
```

Các context:

```text
:create
:edit
:view
:transition
```

---



# 6. Quan trọng: không render lại toàn bộ OpenProject form

Đây là chỗ tôi thay đổi thiết kế so với cách tiếp cận ban đầu.

**Không nên:**

```text
Plugin
  ↓
tự xây toàn bộ Work Package form
```

vì OpenProject đã có form configuration và schema động. ([OpenProject.org](https://www.openproject.org/docs/development/concepts/resource-schemas/?utm_source=chatgpt.com))

Thay vào đó:

```text
Jira UI
   ↓
Screen Resolver
   ↓
Field Configuration Resolver
   ↓
OpenProject API/schema
   ↓
Work Package
```

Frontend React/Vue mà anh đang cân nhắc có thể consume abstraction này.

---



# 7. REST API



### Screens

```http
GET    /api/jira/screens
GET    /api/jira/screens/:id
POST   /api/jira/screens
PUT    /api/jira/screens/:id
DELETE /api/jira/screens/:id
```



### Sections

```http
POST   /api/jira/screens/:id/sections
PUT    /api/jira/screens/:id/sections/:section_id
DELETE /api/jira/screens/:id/sections/:section_id
```



### Fields

```http
POST   /api/jira/screens/:id/items
PUT    /api/jira/screens/:id/items/:item_id
DELETE /api/jira/screens/:id/items/:item_id
```



### Screen Scheme

```http
GET  /api/jira/screen-schemes
POST /api/jira/screen-schemes
PUT  /api/jira/screen-schemes/:id
```



### Project

```http
PUT /api/jira/projects/:project_id/screen-scheme
```



### Resolver endpoint

Đây là API rất quan trọng cho frontend mới của anh:

```http
GET /api/jira/projects/:project_id/
    issue-types/:issue_type_id/
    screens/create
```

Response:

```json
{
  "screen": {
    "id": 12,
    "name": "Bug Create Screen",
    "context": "create"
  },
  "sections": [
    {
      "id": 1,
      "name": "General",
      "position": 1,
      "fields": [
        {
          "key": "subject",
          "position": 1
        },
        {
          "key": "priority",
          "position": 2
        }
      ]
    }
  ]
}
```

Frontend chỉ cần render metadata.

---



# 8. UI quản trị

Menu:

```text
Administration
 └── Jira Configuration
      └── Screens
```

Danh sách:

```text
Screens
────────────────────────────────────────────
Name                  Type        Used by
────────────────────────────────────────────
Bug Create Screen     Create      Bug
Bug Edit Screen       Edit        Bug
Story Create Screen   Create      Story
Story Edit Screen     Edit        Story
```

Editor:

```text
┌──────────────────────────────────────────┐
│ Bug Create Screen                        │
├──────────────────────────────────────────┤
│                                          │
│ General                                  │
│ ┌──────────────────────────────────────┐ │
│ │ Subject                         ⋮    │ │
│ │ Priority                        ⋮    │ │
│ │ Component                       ⋮    │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ Assignment                               │
│ ┌──────────────────────────────────────┐ │
│ │ Assignee                        ⋮    │ │
│ │ Watchers                        ⋮    │ │
│ └──────────────────────────────────────┘ │
│                                          │
│              + Add section               │
└──────────────────────────────────────────┘
```

Có thể drag & drop:

```text
field
  ↓
section
  ↓
position
```

---



# 9. Quan hệ với native OpenProject

Đây là phần cần đặc biệt cẩn thận.

OpenProject hiện đã cho phép cấu hình Work Package form theo Type, bao gồm thêm/bớt/sắp xếp attribute; custom fields cũng được kích hoạt theo project/type. ([OpenProject.org](https://www.openproject.org/docs/system-admin-guide/manage-work-packages/work-package-types/form-configuration/?utm_source=chatgpt.com))

Do đó plugin cần có **compatibility mode**.

### Mode A — Native

```text
Screen config
    ↓
OpenProject native form configuration
```

Plugin chỉ cung cấp abstraction/API.

### Mode B — External UI

Nếu anh triển khai:

```text
Vue/React UI
      ↓
Jira Compatibility API
      ↓
OpenProject API
```

thì Screen metadata trở thành nguồn layout cho frontend riêng.

Đây chính là mode tôi nghĩ **phù hợp nhất với kiến trúc anh đang định triển khai**.

---



# 10. Conflict resolution

Ví dụ:

Feature 02:

```text
Priority = required
```

Feature 03:

```text
Priority = hidden
```

Không được để hai configuration tự mâu thuẫn.

Resolver nên xử lý:

```text
Screen
   ↓
Field exists?
   ↓
Field Configuration
   ↓
visible?
   ↓
required?
   ↓
read-only?
```

Quy tắc:

```text
hidden > screen placement
read-only > editable UI
required + hidden = invalid configuration
```

Đặc biệt:

```text
required = true
visible = false
```

phải bị reject khi configuration được lưu.

---



# 11. Những thứ KHÔNG làm trong Feature 03

Để tránh feature phình quá lớn:

❌ Không tạo Field model mới.

❌ Không tạo Work Package model mới.

❌ Không implement workflow.

❌ Không implement transition validator.

❌ Không implement automation.

❌ Không implement dynamic field behavior.

❌ Không thay thế native OpenProject Form Configuration.

❌ Không sửa OpenProject core nếu chưa bắt buộc.

---



# 12. Acceptance Criteria

Feature được coi là hoàn thành khi:

- [ ] Create Screen
- [ ] Edit Screen
- [ ] View Screen
- [ ] Transition Screen abstraction
- [ ] Screen CRUD
- [ ] Section CRUD
- [ ] Field placement
- [ ] Field ordering
- [ ] Screen Scheme
- [ ] Issue Type → Screen mapping
- [ ] Project → Screen Scheme mapping
- [ ] Resolver API
- [ ] Conflict validation với Field Configuration
- [ ] REST API
- [ ] Permission
- [ ] Migration
- [ ] Automated tests
- [ ] Không tạo duplicate Work Package/Field model
- [ ] Không modify OpenProject core domain model

---



# 13. Dependency

Sau ba feature:

```text
01 Issue Type Scheme
          │
          ▼
02 Field Configuration
          │
          ▼
03 Screen & Layout
          │
          ▼
04 Jira-style Issue View
          │
          ▼
05 Issue Navigator
```

**Tôi đánh giá Feature 03 là feature có giá trị kiến trúc cao nhưng không nên cố “đánh nhau” với native OpenProject.** Native OpenProject đã làm khá nhiều phần layout; plugin của chúng ta nên cung cấp **Jira-compatible abstraction + resolver + API**, đặc biệt để phục vụ frontend Vue/React riêng của anh. ([OpenProject.org](https://www.openproject.org/docs/system-admin-guide/manage-work-packages/work-package-types/form-configuration/?utm_source=chatgpt.com))

### Một điều chỉnh quan trọng cho roadmap

Sau khi kiểm tra tài liệu hiện tại, tôi sẽ **không coi Feature 03 là “xây lại form configuration”** nữa. Nó là:

> **Screen/Scheme orchestration layer trên native OpenProject Form Configuration.**

Điều này giúp giảm đáng kể effort và tránh tạo một “OpenProject thứ hai” bên trong plugin.

**Feature tiếp theo sẽ là Idea 04 — Jira-style Issue View**, nơi bắt đầu có giá trị UI rõ rệt hơn: bố cục issue detail kiểu Jira, tabs/sections, activity, fields, links, hierarchy…