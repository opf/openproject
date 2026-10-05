# Feature 01 — Issue Type Scheme

## 1. Mục tiêu

OpenProject đã có:

* Work Package
* Work Package Type
* Project
* Custom Field
* Status
* Workflow

Nhưng Jira có thêm một lớp quản trị:

```text
Project
   ↓
Issue Type Scheme
   ↓
Allowed Issue Types
```

Feature này bổ sung lớp **Issue Type Scheme** để quản lý:

* Project nào được sử dụng Type nào
* Thứ tự Type
* Type mặc định
* Type nào được phép tạo
* Type nào bị disable
* cấu hình Type theo nhóm Project

Quan trọng:

> **Không tạo `JiraIssueType` mới.**

Plugin chỉ quản lý/mapping các `OpenProject::Type` hiện có.

---

# 2. Ví dụ

OpenProject hiện có:

```text
Types
├── Task
├── Bug
├── User Story
├── Epic
├── Milestone
└── Feature
```

Plugin cho phép tạo:

```text
Software Development Scheme
├── Epic
├── User Story
├── Task
├── Bug
└── Sub-task
```

Sau đó:

```text
Project: CRM

Issue Type Scheme
        │
        ├── Epic
        ├── User Story
        ├── Task
        └── Bug
```

Trong khi:

```text
Project: Infrastructure

Issue Type Scheme
        │
        ├── Task
        ├── Bug
        └── Change
```

---

# 3. Vấn đề hiện tại cần giải quyết

Nếu chỉ dùng OpenProject native, Type thường được quản lý ở cấp hệ thống/project theo cơ chế có sẵn.

Plugin muốn tạo abstraction:

```text
System Types
     │
     ├── Task
     ├── Bug
     ├── Story
     ├── Epic
     └── Change
          │
          ▼
     Type Schemes
          │
     ├── Scrum Scheme
     ├── Kanban Scheme
     └── ITSM Scheme
          │
          ▼
       Projects
```

Điều này giúp sau này các plugin:

* Backlog
* Scrum Board
* Workflow
* Field Configuration
* Automation

đều có thể dựa vào cùng một metadata layer.

---

# 4. User Stories

### US-01 — Tạo Scheme

Admin tạo:

```text
Software Development
```

và chọn:

```text
☑ Epic
☑ Story
☑ Task
☑ Bug
☐ Change
☐ Milestone
```

---

### US-02 — Gán Scheme cho Project

```text
Project: CRM

Issue Type Scheme:
[ Software Development ▼ ]
```

Sau đó khi Create Work Package:

```text
Type
┌────────────────────┐
│ Story           ▼  │
└────────────────────┘
```

chỉ hiện các Type được phép.

---

### US-03 — Default Type

Scheme:

```text
Software Development

Epic
Story       ← Default
Task
Bug
```

Khi:

```text
Create Issue
```

mặc định:

```text
Type = Story
```

---

### US-04 — Ordering

Scheme:

```text
1. Epic
2. Story
3. Task
4. Bug
```

UI Create Issue cũng sử dụng thứ tự này.

---

### US-05 — Disable Type

Admin bỏ:

```text
Bug
```

khỏi scheme.

Các issue Bug **đã tồn tại vẫn giữ nguyên**.

Nhưng issue mới không được tạo với Type `Bug`.

Đây là distinction rất quan trọng:

```text
Existing data
       ≠
Allowed new issue types
```

---

# 5. Domain Model

Tôi đề xuất 3 bảng chính.

```text
jira_issue_type_schemes
jira_issue_type_scheme_items
jira_project_type_scheme
```

## 5.1 `jira_issue_type_schemes`

```text
id
name
description
is_default
active
created_at
updated_at
```

Ví dụ:

```text
id: 1
name: Software Development
description: Standard Scrum development scheme
active: true
```

---

## 5.2 `jira_issue_type_scheme_items`

```text
id
scheme_id
openproject_type_id
position
is_default
created_at
updated_at
```

Ví dụ:

```text
scheme_id | type_id | position | default
----------+---------+----------+--------
1         | 10      | 1        | false
1         | 11      | 2        | true
1         | 12      | 3        | false
1         | 13      | 4        | false
```

Trong đó `type_id` trỏ tới **OpenProject Type**.

---

## 5.3 `jira_project_type_scheme`

```text
id
project_id
scheme_id
created_at
updated_at
```

Constraint:

```text
UNIQUE(project_id)
```

Một Project chỉ có **một active scheme** tại một thời điểm.

---

# 6. Quan hệ

```text
OpenProject Project
        │
        │ 1:1
        ▼
jira_project_type_scheme
        │
        │ N:1
        ▼
jira_issue_type_schemes
        │
        │ 1:N
        ▼
jira_issue_type_scheme_items
        │
        │ N:1
        ▼
OpenProject Type
```

Điểm quan trọng:

```text
Plugin Type
     ↓
không tồn tại
```

Mà:

```text
Plugin Scheme
     ↓
tham chiếu
     ↓
OpenProject Type
```

---

# 7. UI — Administration

Thêm menu:

```text
Administration
 └── Jira Configuration
       └── Issue Type Schemes
```

Danh sách:

```text
Issue Type Schemes

┌──────────────────────────────┬─────────┬──────────┐
│ Name                         │ Projects│ Status   │
├──────────────────────────────┼─────────┼──────────┤
│ Software Development         │ 12      │ Active   │
│ Kanban                       │ 8       │ Active   │
│ IT Operations                │ 4       │ Active   │
└──────────────────────────────┴─────────┴──────────┘
```

Actions:

```text
Create
Edit
Clone
Deactivate
Delete
```

---

# 8. UI — Create/Edit Scheme

```text
Software Development

Name
┌──────────────────────────────┐
│ Software Development         │
└──────────────────────────────┘

Description
┌──────────────────────────────┐
│ Standard Scrum scheme        │
└──────────────────────────────┘


Issue Types

☰  Epic
☰  Story       ● Default
☰  Task
☰  Bug
☰  Sub-task

             [+ Add Issue Type]

                    [Save]
```

`☰` hỗ trợ drag & drop.

---

# 9. UI — Project Settings

Trong:

```text
Project
 → Settings
 → Jira Configuration
```

hiển thị:

```text
Issue Type Scheme

┌───────────────────────────────┐
│ Software Development       ▼  │
└───────────────────────────────┘
```

Bên dưới:

```text
Available Issue Types

Epic
Story
Task
Bug
Sub-task
```

---

# 10. Create Work Package

Khi user tạo issue:

```text
Create Work Package

Subject
────────────────────────

Type
┌───────────────────────┐
│ Story              ▼  │
└───────────────────────┘
```

Plugin filter Type dựa trên:

```text
Current Project
      ↓
Assigned Scheme
      ↓
Allowed Types
```

Không sửa Work Package model.

---

# 11. Default Scheme

Có thể cấu hình:

```text
Default Scheme
```

Ví dụ:

```text
Software Development
```

Khi tạo project mới:

```text
New Project
    ↓
Auto assign default Issue Type Scheme
```

Admin có thể disable behavior này.

---

# 12. Type chưa được Scheme sử dụng

Giả sử OpenProject có:

```text
Task
Bug
Story
Epic
Change
```

Scheme chỉ có:

```text
Task
Bug
Story
```

Issue hiện tại:

```text
CRM-123
Type = Change
```

vẫn phải hiển thị bình thường.

Không được làm:

```text
Change → Task
```

Plugin chỉ kiểm soát **creation/configuration**, không phá dữ liệu hiện hữu.

---

# 13. Scheme thay đổi

Ví dụ:

```text
Current:

Epic
Story
Task
Bug
```

Admin remove:

```text
Bug
```

Hệ thống cảnh báo:

```text
Bug type is currently used by 42 work packages.

Removing it from this scheme will prevent
creation of new Bug issues.

Existing issues will not be changed.

[Cancel] [Confirm]
```

---

# 14. Scheme được sử dụng bởi nhiều Project

Ví dụ:

```text
Software Development Scheme

Projects:
├── CRM
├── ERP
├── HR
├── Mobile
└── Portal
```

Nếu sửa scheme:

```text
Remove Bug
```

thay đổi áp dụng cho tất cả project.

Do đó UI phải cảnh báo:

```text
This scheme is used by 5 projects.
Changes will affect all projects.
```

---

# 15. Clone Scheme

Rất hữu ích.

```text
Software Development
        │
        └── Clone
              ↓
Software Development - Custom
```

Sau đó PM có thể thay đổi:

```text
Epic
Story
Task
Bug
Security Issue
```

mà không ảnh hưởng scheme gốc.

---

# 16. Delete Policy

Không cho delete nếu:

```text
Scheme đang được Project sử dụng
```

Hiển thị:

```text
Cannot delete this scheme.

It is currently assigned to:
CRM
ERP
Portal
```

Phải:

```text
Reassign projects
      ↓
Delete
```

---

# 17. Permission

Tận dụng OpenProject permission hiện có nếu có thể.

Tôi đề xuất thêm **2 plugin permissions**:

```text
Manage Issue Type Schemes
Assign Issue Type Scheme
```

Mapping:

| Action                | Permission         |
| --------------------- | ------------------ |
| View Scheme           | View configuration |
| Create Scheme         | Manage Scheme      |
| Edit Scheme           | Manage Scheme      |
| Delete Scheme         | Manage Scheme      |
| Assign Project        | Assign Scheme      |
| Change project scheme | Assign Scheme      |

Không tạo permission matrix phức tạp hơn cần thiết ở Feature 01.

---

# 18. API

Plugin cung cấp REST API riêng.

### List

```http
GET /api/jira/issue-type-schemes
```

### Detail

```http
GET /api/jira/issue-type-schemes/:id
```

### Create

```http
POST /api/jira/issue-type-schemes
```

Body:

```json
{
  "name": "Software Development",
  "description": "Standard Scrum scheme",
  "issue_types": [
    {
      "type_id": 10,
      "position": 1
    },
    {
      "type_id": 11,
      "position": 2,
      "default": true
    },
    {
      "type_id": 12,
      "position": 3
    }
  ]
}
```

### Assign Project

```http
PUT /api/jira/projects/:project_id/issue-type-scheme
```

```json
{
  "scheme_id": 1
}
```

### Resolve

API rất quan trọng cho các plugin sau:

```http
GET /api/jira/projects/:project_id/available-issue-types
```

Response:

```json
{
  "scheme": {
    "id": 1,
    "name": "Software Development"
  },
  "issue_types": [
    {
      "id": 10,
      "name": "Epic",
      "position": 1
    },
    {
      "id": 11,
      "name": "Story",
      "position": 2,
      "default": true
    },
    {
      "id": 12,
      "name": "Task",
      "position": 3
    }
  ]
}
```

---

# 19. Service Layer

Tôi muốn plugin có service rõ ràng:

```text
IssueTypeSchemeService
├── create
├── update
├── clone
├── deactivate
├── assign_to_project
├── unassign_from_project
├── available_types
└── validate
```

Và:

```text
ProjectIssueTypeResolver
```

API nội bộ:

```ruby
resolver.for_project(project)
```

returns:

```text
IssueTypeScheme
```

Các plugin sau sẽ dùng service này thay vì truy vấn trực tiếp DB.

---

# 20. Validation

### Scheme

Không cho:

```text
name = blank
```

### Type

Không cho duplicate:

```text
Story
Story
```

### Default

Mỗi scheme:

```text
0 hoặc 1 default
```

Nếu muốn giống Jira chặt chẽ hơn:

```text
exactly 1 default
```

Tôi khuyến nghị **exactly 1** khi scheme active.

---

# 21. Core Modification

Mục tiêu:

```text
OpenProject Core Modification
= 0
```

Plugin chỉ:

```text
OpenProject Type
        ↑
        │ reference
        │
Jira Type Scheme
```

Không:

* fork Type
* sửa WorkPackage
* sửa Project
* thêm field vào core tables nếu không cần
* thay native Type model

Chỉ cần extension ở UI Create/Edit để filter available types.

Nếu extension point của phiên bản OpenProject anh đang dùng không đủ sạch, đây là **điểm cần kiểm tra trước khi code**, không nên tự động dùng monkey patch.

---

# 22. Migration

Install plugin:

```text
Existing OpenProject
       ↓
Plugin installed
       ↓
Create default scheme
```

Ví dụ:

```text
Default Scheme
├── Task
├── Bug
├── User Story
└── Milestone
```

Sau đó project hiện tại:

```text
Project A → Default Scheme
Project B → Default Scheme
...
```

Nhưng tôi khuyến nghị migration có chế độ:

```text
AUTO
DRY RUN
MANUAL
```

Trong production:

> **DRY RUN → review → APPLY**

---

# 23. Compatibility

Nếu uninstall plugin:

```text
jira_issue_type_schemes
jira_issue_type_scheme_items
jira_project_type_scheme
```

bị remove hoặc disable tùy migration strategy.

Nhưng:

```text
OpenProject Type
OpenProject WorkPackage
```

**không được mất dữ liệu**.

Đây là nguyên tắc bắt buộc.

---

# 24. Test

### Unit

```text
SchemeValidator
TypeSchemeResolver
DefaultTypeResolver
SchemeAssignmentService
```

### Integration

```text
Create scheme
Assign scheme
Resolve scheme
Add type
Remove type
Clone scheme
Deactivate scheme
```

### Data integrity

Test:

```text
Remove type from scheme
```

không làm mất Work Package.

### Multi-project

```text
Scheme A
  ├── Project 1
  ├── Project 2
  └── Project 3
```

sửa Scheme A → cả 3 project nhận thay đổi.

---

# 25. Acceptance Criteria

Feature 01 đạt khi:

* [ ] Admin tạo được Issue Type Scheme.
* [ ] Scheme sử dụng **OpenProject Type native**.
* [ ] Có thể thêm/remove Type khỏi Scheme.
* [ ] Có thể reorder Type.
* [ ] Có một default Type.
* [ ] Có thể assign Scheme cho Project.
* [ ] Một Project chỉ có một active Scheme.
* [ ] Create Issue chỉ hiển thị Type thuộc Scheme.
* [ ] Existing Work Package không bị ảnh hưởng khi Type bị remove khỏi Scheme.
* [ ] Có cảnh báo khi thay đổi Scheme đang được nhiều Project sử dụng.
* [ ] Có clone Scheme.
* [ ] Không xóa Scheme đang được sử dụng.
* [ ] Có REST API.
* [ ] Có permission.
* [ ] Có migration.
* [ ] Không sửa OpenProject core data model.
* [ ] Plugin có automated tests.

---

# 26. Dependency cho các Feature sau

Đây mới là lý do Feature 01 quan trọng.

```text
                 Issue Type Scheme
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
 Field Configuration   Screens      Workflow
          │             │             │
          └─────────────┼─────────────┘
                        ▼
                   Issue View
                        │
                        ▼
                     Backlog
                        │
                        ▼
                      Sprint
                        │
                        ▼
                    Scrum Board
```

Đặc biệt:

### Feature 02 — Field Configuration

Có thể nói:

```text
IF
    Project = CRM
    AND Issue Type = Bug

THEN

    Priority = Required
    Environment = Required
    Sprint = Optional
```

### Feature 03 — Screen/Layout

Có thể nói:

```text
Bug
 ↓
Bug Screen

Story
 ↓
Story Screen
```

### Feature 13 — Workflow

Có thể nói:

```text
Bug
 ↓
Bug Workflow

Story
 ↓
Story Workflow
```

Vì vậy **Issue Type Scheme không phải một tính năng UI đơn lẻ**. Nó là metadata foundation cho toàn bộ Jira compatibility layer.
