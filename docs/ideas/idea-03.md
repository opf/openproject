# Feature 03 — Issue Screen & Layout

Feature 01 quyết định **Type nào được dùng**. Feature 02 quyết định **field có hidden / required / read-only / default**. Feature 03 quyết định **field nào nằm ở đâu, theo thứ tự nào, trên màn hình nào (tạo / sửa / xem)**.

> Jira chỉ xuất hiện ở tài liệu này như **mốc so sánh để hiểu khoảng trống**. Không dùng tên, bảng, route, permission hay menu của Jira trong thiết kế. Hệ thống, chức năng và DB đều theo quy ước của OpenProject và Feature 01–02.

## 0. Hội đồng chuyên gia PO — Review & Revision (2026-10-05)

Bản idea gốc được review lại bởi hội đồng 5 PO, mỗi người nhìn từ một góc. Phần này ghi kết luận; các mục 1–14 là đặc tả đã viết lại theo kết luận đó.

| PO | Góc nhìn | Vấn đề chính chỉ ra trong bản gốc |
|---|---|---|
| PO-1 Sản phẩm / giá trị | Người dùng thực sự được lợi gì | Bản gốc mô tả kiến trúc, không có người dùng, vấn đề, hay thước đo thành công. Chức năng `Transition Screen` không có người dùng nào cho đến khi Workflow tồn tại. |
| PO-2 Nền tảng / kiến trúc | Khớp với code thật của OpenProject | Layout native đã có sẵn theo Project × Type (variant + nhóm). Bản gốc lẫn lộn "layout" với "enforcement" và đề xuất một chuỗi `Project → Issue Type Scheme → Screen Scheme → Type` dư một tầng. |
| PO-3 Quản trị / UX | Admin cấu hình và hiểu hệ quả | Thiếu quy tắc dùng chung screen giữa nhiều type/project, thiếu cảnh báo tác động, thiếu cách cho admin biết "vì sao field này không hiện". |
| PO-4 Tích hợp / API | Frontend và hệ thống khác dùng ra sao | Bản gốc dùng `/api/jira/...`, bỏ qua API v3 (HAL). Chưa nói ai tiêu thụ payload layout và chưa định nghĩa hành vi khi không có screen. |
| PO-5 Dữ liệu / vận hành / chất lượng | Migration, hiệu năng, rủi ro, kiểm thử | Tên bảng `jira_*`; trường `visible`, `width` không có bên tiêu thụ; chưa có chiến lược fail-open, cache, hay xử lý field bị xoá/không còn khả dụng. |

### 0.1 Phát hiện đã đối chiếu với code

| # | Phát hiện | Bằng chứng | Hệ quả |
|---|---|---|---|
| H1 | **Layout theo Project × Type đã tồn tại.** Mỗi project dùng một `TypeVariant` cho mỗi type; variant gắn với `FormConfiguration` gồm các group (nhóm thuộc tính, và nhóm bảng work package liên quan — query group). | `app/models/form_configuration.rb`, `form_configuration_group.rb`, `type_variant.rb` | Không được tạo lại editor "form" song song. Screen chỉ là lớp mới ở **chiều còn thiếu**: layout theo ngữ cảnh (create/edit/view) và dùng chung giữa nhiều type/project. |
| H2 | **Native chỉ có một layout cho mọi ngữ cảnh.** Tạo, sửa, xem đều dùng cùng danh sách group từ `type_variant.attribute_groups`, được đưa ra qua schema API v3 dưới khoá `_attributeGroups`. | `lib/api/v3/work_packages/schema/work_package_schema_representer.rb:117,386` | Khoảng trống thật: **layout khác nhau theo ngữ cảnh** (ví dụ form tạo gọn, form xem đầy đủ) và **tái sử dụng một layout cho nhiều type**. |
| H3 | **Native không có màn hình chuyển trạng thái.** Đổi status là một field; Workflow chỉ quyết định status nào được chọn. | Không có khái niệm tương ứng trong core | `Transition Screen` bị loại khỏi V1 (xem Q1). Không tạo trước một abstraction chưa có người dùng. |
| H4 | **Danh sách field có thể đặt lên screen không trùng allowlist của Feature 02.** F02 cố ý loại `subject`, `status`, `type`, `parent`… (không cấu hình hidden/required được) nhưng layout vẫn phải đặt được chúng. | `docs/superpowers/specs/2026-10-03-field-rules-design.md` §5 | Tập "field đặt được lên screen" lấy từ `TypeVariant#work_package_attributes` + custom field đang active, **không** dùng allowlist F02. Vẫn không có model `Field`. |
| H5 | **Xung đột thật giữa F02 và F03 không phải `required + hidden`** (đó là lỗi nội bộ F02). Xung đột thật là: (a) field `required` mà **không có trên screen tạo** ⇒ không thể tạo work package; (b) field `hidden` mà **được đặt lên screen** ⇒ rule mâu thuẫn; (c) field trên screen nhưng không còn khả dụng (custom field bị tắt ở project). | `modules/field_rules` Resolver/EffectiveConfiguration | Viết lại mục xung đột (mục 8). |
| H6 | **Quy ước đã chốt ở F01/F02 phải theo:** không có "jira" trong tên; API v3 HAL; module `modules/*`; manage = admin, assign = permission project; không xoá khi đang dùng (deactivate); không sửa file core, chỉ prepend/extension point; fail-open; cache theo request. | `docs/superpowers/specs/2026-10-02-type-scheme-design.md`, `2026-10-03-field-rules-design.md` | Áp nguyên cho F03. Đặt tên `Screen*`, module `modules/screens`. Đã kiểm tra: chưa có class/bảng `Screen*` trong core hoặc module. |
| H7 | **F01 đã lọc Type theo project**, nên chuỗi `Issue Type Scheme → Screen Scheme` ở bản gốc dư. Screen Scheme chỉ cần ánh xạ **Type → screen cho từng ngữ cảnh**, giống `FieldRuleScheme` (Type → Rule Set). | F01 §13, F02 §3 | Bỏ tầng thừa; ba feature có cùng hình dạng: Scheme gán cho project, item ánh xạ Type → cấu hình. |

### 0.2 Quyết định thiết kế đã sửa

1. **Screen là metadata trình bày, không phải ranh giới enforcement.** Screen không chặn ghi field nào qua API, không thay contract, không thay đổi `writable`/`required` của schema. Chặn/bắt buộc/chỉ-đọc là việc của Feature 02 và native. Hệ quả: tạo work package qua API/import/mail vẫn hoạt động bất kể screen.
2. **V1 không ghi vào `FormConfiguration` native và không sửa Angular native.** Layout native vẫn là mặc định. Screen được phát qua API v3 cho bên tiêu thụ (Feature 04 và frontend mới). Đây là hướng duy nhất tránh "OpenProject thứ hai" và tránh hai nguồn sự thật cho cùng một bố cục (ghi chú tại Q2).
3. **Không có scheme gán ⇒ layout native** (`source: native`), giống F02, không tạo Default Screen Scheme tự động (screen rỗng không có nghĩa). Khác F01 vì F01 là allow-list bắt buộc, F03 là lớp bổ sung.
4. **Ba ngữ cảnh V1: `create`, `edit`, `view`.** Thứ tự fallback khi một ngữ cảnh chưa gán screen: `view → edit → native`; `edit → native`; `create → native`. `transition` hoãn.
5. **Bỏ `visible` và `width` khỏi item.** Item tồn tại = field được đặt; muốn ẩn thì xoá khỏi screen (hoặc dùng Field Rule `hidden`). `width`/cột chỉ thêm khi Feature 04 có nhu cầu cụ thể (thêm cột sau là migration rẻ, thêm rồi bỏ thì không).
6. **Mỗi field xuất hiện tối đa một lần trên một screen** (ràng buộc DB + validation).
7. **Đổi tên theo quy ước:** `Screen`, `ScreenSection`, `ScreenItem`, `ScreenScheme`, `ScreenSchemeItem`, `ProjectScreenScheme`; bảng `screens`, `screen_sections`, `screen_items`, `screen_schemes`, `screen_scheme_items`, `project_screen_schemes`; module `modules/screens`; không có "jira" ở bất kỳ đâu.
8. **Không xoá screen/scheme đang được dùng**; deactivate (inactive = bị bỏ qua, project dùng native). Xoá section/item trong screen là sửa nội dung nên được phép.
9. **Resolver trả cấu hình hợp nhất**, không bắt frontend tự gọi hai nơi: layout (F03) + trạng thái hiệu lực của từng field (F02/native) + `diagnostics`.
10. **Fail-open:** lỗi trong resolver không làm hỏng tạo/sửa/xem work package; ghi log và rơi về `source: native`.

### 0.3 Rủi ro đã nhận diện

* **Hai nguồn layout** (native form configuration vs Screen) làm admin nhầm. Giảm thiểu: UI luôn hiển thị nguồn đang có hiệu lực cho từng (project, type, ngữ cảnh) và cảnh báo khi cả hai khác nhau; tài liệu nói rõ native vẫn là mặc định cho giao diện OpenProject hiện tại.
* **Screen dùng chung bị sửa gây tác động rộng:** sửa một screen đang dùng ở nhiều scheme/project phải qua trang xác nhận nêu số scheme/project/type bị ảnh hưởng (như F01 §12).
* **Field "mồ côi"** (custom field bị tắt hoặc xoá, field của module bị gỡ): item bị bỏ qua lúc resolve, hiển thị cảnh báo trong editor, không làm lỗi payload.
* **Hiệu năng:** resolve được gọi cho mỗi lần mở work package; cache theo (project, type, ngữ cảnh) trong request, preload theo lô cho danh sách; không truy vấn trong vòng lặp từng work package.
* **Lệch với F02:** F02 có thể thêm rule `hidden`/`required` sau khi screen đã tạo. Kiểm tra phải chạy ở cả hai chiều (lưu screen scheme và lưu rule), và luôn có `diagnostics` ở runtime.
* **Phạm vi phình to** (blocks activity/relations/hierarchy): thuộc Feature 04, không đưa vào đây.

### 0.4 Phạm vi V1 sau review

**In:** Screen (create/edit/view), Section, Item (đặt field + thứ tự), Screen Scheme (Type → create/edit/view screen), gán cho project, Resolver hợp nhất với trạng thái field F02, API v3, admin UI, project settings, permission, migration, test.

**Out (hoãn, có lý do):**

* `transition` screen — chờ Workflow (Q1).
* Item không phải field: bảng work package liên quan, activity, relations, files (Feature 04).
* `width`/nhiều cột (Feature 04 quyết định).
* Ghi ngược vào `FormConfiguration` native hoặc sửa Angular native (Q2).
* Kế thừa/ghi đè theo project, import/export screen, versioning.
* Enforcement dựa trên screen.

---

## 1. Vấn đề và người dùng

| Người dùng | Việc cần làm | Đau hiện tại |
|---|---|---|
| Admin hệ thống | Định nghĩa bố cục chuẩn cho Bug/Story/Task và dùng chung cho nhiều project | Phải cấu hình form từng Type riêng, không tái sử dụng được, không có bố cục riêng cho tạo và xem |
| Quản lý project | Chọn bộ bố cục phù hợp cho project của mình | Không có cách chọn; mọi project giống nhau theo Type |
| Người dùng cuối | Form tạo gọn, chỉ field cần thiết; trang xem đầy đủ | Form tạo và trang xem cùng một danh sách dài |
| Nhà phát triển frontend/tích hợp | Một nguồn metadata layout rõ ràng | Phải suy ra bố cục từ `_attributeGroups` theo từng variant, không có ngữ cảnh |

Thước đo thành công: số type dùng chung screen; thời gian admin cấu hình một bố cục mới cho một type (mục tiêu: không cần mở form configuration của từng type); số lỗi `diagnostics` ở production (mục tiêu: 0 sau khi cấu hình hợp lệ).

## 2. So sánh để hiểu khoảng trống (không phải thiết kế)

| Câu hỏi | Jira (chỉ để đối chiếu) | OpenProject hiện tại | Feature 03 bổ sung |
|---|---|---|---|
| Layout phụ thuộc gì? | Issue Type + thao tác | Project × Type (variant) | Thêm chiều **ngữ cảnh** |
| Dùng chung layout? | Có, screen dùng nhiều nơi | Không (variant gắn với type) | Screen dùng chung qua Screen Scheme |
| Layout khác nhau tạo/sửa/xem? | Có | Không (một layout) | `create` / `edit` / `view` |
| Gán cho project? | Qua scheme | Qua việc project dùng variant | Qua `ProjectScreenScheme` |

Chi tiết cách Jira đặt tên các lớp không được sao chép; ba feature đã chọn hình dạng thống nhất riêng (Scheme gán cho project; item ánh xạ Type → cấu hình).

## 3. Phân biệt ba feature và native

| Lớp | Trả lời câu hỏi | Nơi sở hữu |
|---|---|---|
| Issue Type Scheme (F01) | Type nào được dùng? | `type_schemes` |
| Field Rule (F02) | Field hidden / required / read-only / default? | `field_rules` |
| **Screen & Layout (F03)** | **Field nằm ở đâu, theo thứ tự nào, trên ngữ cảnh nào?** | `screens` |
| Native form configuration | Layout mặc định theo Project × Type | core |
| Workflow | Chuyển trạng thái thế nào? | core / feature sau |

Ví dụ: type Bug

```text
Field Rule (F02):   priority required · assignee optional · environment required
Screen "Bug Create": [Details] subject, description, environment, priority
                     [Assignment] assignee
Screen "Bug View":   [Details] subject, description, environment, priority, status
                     [People] assignee, responsible
                     [Planning] start_date, due_date, estimated_time
```

**Configuration ≠ Layout:** screen không lưu required/hidden/read-only/default; không có model `Field`.

## 4. Domain model

```text
screens                id, name (unique, ≤255), description (≤5000),
                       context enum {create, edit, view}, active, timestamps
screen_sections        id, screen_id FK cascade, name (≤255), position, timestamps
                       UNIQUE(screen_id, name)
screen_items           id, screen_id FK cascade, section_id FK cascade,
                       field_key, position, timestamps
                       UNIQUE(screen_id, field_key)
screen_schemes         id, name (unique, ≤255), description, active, timestamps
screen_scheme_items    id, scheme_id FK cascade, type_id FK cascade,
                       create_screen_id FK null, edit_screen_id FK null,
                       view_screen_id FK null
                       UNIQUE(scheme_id, type_id)
project_screen_schemes id, project_id FK cascade UNIQUE, scheme_id FK
```

Quy tắc dữ liệu:

* `field_key` không có FK: là khoá thuộc tính work package (`subject`, `description`, `status`, `priority`, `assignee`, `due_date`, `custom_field_<id>`…), validate theo tập "đặt được" ở mục 5. Không tạo bảng/model `Field`.
* Một screen thuộc đúng một `context`; `screen_scheme_items.create_screen_id` chỉ nhận screen `context = create`, v.v. (validation + test).
* FK `screen_id`/`scheme_id` trong `screen_scheme_items`/`project_screen_schemes` **không** cascade; model chặn `destroy` khi đang được dùng (deactivate thay thế).
* Không thêm cột/bảng vào bảng core. `type_id` trỏ tới `types` native.
* `position` của section và item: số nguyên liên tiếp, chuẩn hoá khi lưu.

## 5. Field đặt được lên screen

Tập hợp được tính, không lưu:

```text
placeable(project, type) =
    TypeVariant#work_package_attributes (native, đã qua constraint của module)
  ∪ custom field active của project áp cho type
```

* Screen dùng chung nên **validation lưu screen chỉ kiểm tra key hợp lệ toàn cục** (là attribute native đã biết hoặc `custom_field_<id>` của một WorkPackageCustomField tồn tại).
* Kiểm tra khả dụng theo (project, type) được làm ở **resolver** và ở **cảnh báo tác động** (mục 8), vì cùng một screen có thể dùng cho nhiều project.
* Không đặt được: field tự sinh hoặc không có nghĩa trên form (`id`, `created_at`, `updated_at`, `author` ở ngữ cảnh create) — danh sách tường minh trong registry `Screens::Fields`.

## 6. Resolver

Service `Screens::Resolver`:

```ruby
Screens::Resolver.for(project:, type:, context:) # => ResolvedScreen
```

Thuật toán:

1. Tìm `ProjectScreenScheme` active của project; không có ⇒ `source: native`.
2. Tìm `screen_scheme_items` của type; áp fallback ngữ cảnh (mục 0.2.4); không có screen active ⇒ `source: native`.
3. Với mỗi item: kiểm tra field thuộc `placeable(project, type)`; không thuộc ⇒ bỏ qua và ghi `diagnostics.unavailable`.
4. Ghép trạng thái hiệu lực từ `FieldRules::Resolver` (nếu module F02 bật): `hidden`, `required`, `read_only`, `default`, `source`.
5. Field `hidden` bị **loại khỏi sections** và ghi `diagnostics.hidden_but_placed`.
6. Field `required` mà không nằm trên screen `create` (và không có default) ghi `diagnostics.required_not_placed`.
7. Trả kết quả không đổi (immutable), cache theo request.

Hợp đồng đầu ra:

```json
{
  "source": "screen",
  "context": "create",
  "screen": { "id": 12, "name": "Bug Create" },
  "sections": [
    {
      "id": 1, "name": "Details", "position": 1,
      "items": [
        { "key": "subject",  "position": 1, "state": { "required": true,  "readOnly": false } },
        { "key": "priority", "position": 2, "state": { "required": true,  "readOnly": false, "default": 3 } }
      ]
    }
  ],
  "diagnostics": { "unavailable": [], "hidden_but_placed": [], "required_not_placed": [] }
}
```

`source: native` ⇒ `screen` và `sections` rỗng; bên tiêu thụ dùng layout native.

## 7. API v3 (HAL)

Theo quy ước F01/F02; không có `/api/jira/...`.

```text
GET    /api/v3/screens                 (view: admin)
POST   /api/v3/screens                 (admin)
GET    /api/v3/screens/:id
PATCH  /api/v3/screens/:id             (admin; gồm sections + items lồng nhau)
POST   /api/v3/screens/:id/activate    (admin)
POST   /api/v3/screens/:id/deactivate  (admin)

GET/POST/PATCH /api/v3/screen_schemes[/:id]            (admin)
PUT    /api/v3/projects/:id/screen_scheme              (permission assign_screen_scheme)

GET    /api/v3/projects/:id/types/:type_id/screens/:context   (view_work_packages)
```

* Endpoint cuối là kênh chính cho frontend; `context ∈ create|edit|view`, giá trị khác trả 422.
* Không có `DELETE` cho screen/scheme (mục 0.2.8). Section/item xoá qua `PATCH` (thay thế danh sách lồng) hoặc endpoint con nếu cần diff nhỏ.
* Lỗi theo cấu trúc chuẩn API v3; mã ổn định: `unknown_field`, `duplicate_field`, `context_mismatch`, `in_use`.
* `PUT .../screen_scheme` với `scheme_id` không tồn tại hoặc inactive ⇒ 422.

## 8. Xung đột với Feature 02 và kiểm tra khi lưu

| Tình huống | Khi lưu screen/scheme | Khi resolve (runtime) |
|---|---|---|
| Field `required` (F02/native) không có trên screen `create` và không có default | **Từ chối** lưu scheme item gán screen đó cho type, kèm danh sách field thiếu | `diagnostics.required_not_placed`, vẫn trả layout |
| Field `hidden` (F02) có trên screen | **Cảnh báo** (không chặn), vì rule có thể thay đổi sau | Loại khỏi sections, `hidden_but_placed` |
| Field không khả dụng ở project/type | Cảnh báo tác động ("không khả dụng trong N project") | Bỏ qua, `unavailable` |
| Screen sai ngữ cảnh | Từ chối `context_mismatch` | — |
| Lưu rule F02 làm một screen đang dùng vi phạm | F02 không biết F03; resolver `diagnostics` là kênh phát hiện | `diagnostics` |

Thứ tự ưu tiên khi hợp nhất: **native/F02 quyết định trạng thái field; Screen chỉ quyết định vị trí.** Screen không bao giờ làm hiện field mà native/F02 ẩn, và không bao giờ thay đổi `required`/`read_only`.

## 9. UI quản trị

* **Administration → Work packages → Screens** (cùng khu vực F01/F02, tên menu theo i18n, không "Jira").
  * Danh sách screen: Name, Context, Used by (số scheme/type), Status; hành động Create / Edit / Clone / Deactivate. Không có Delete.
  * Editor: danh sách section có thể thêm/đổi tên/sắp xếp; trong mỗi section là danh sách field. Chọn field qua bộ chọn (đã trừ những field đã đặt); đổi thứ tự bằng kéo-thả **và** nút Lên/Xuống (Alt+↑/↓) với `aria-live`, vị trí vẫn ghi vào ô số khi tắt JS (theo F01 §13.3).
  * Cảnh báo tác động trước khi lưu một screen đang được dùng.
* **Administration → Work packages → Screen schemes:** bảng Type × (Create / Edit / View) chọn screen theo dropdown; hiển thị chẩn đoán xung đột (mục 8) ngay trong bảng.
* **Project Settings → Work packages → Screen scheme:** dropdown scheme + xem trước layout theo (type, ngữ cảnh) và nguồn hiệu lực (`screen` / `native`).
* Dùng Primer/ViewComponent + Turbo + Stimulus như F01/F02; không thêm Angular mới.

## 10. Phân quyền

| Hành động | Quyền |
|---|---|
| Quản lý screen, section, item, scheme | Admin |
| Gán scheme cho project | `assign_screen_scheme` (project permission, admin cấp cho role) |
| Đọc layout đã resolve | `view_work_packages` của project |

## 11. Điểm chạm core

* Không sửa file core, không thêm cột vào bảng core.
* Đọc: `TypeVariant#work_package_attributes`, `custom_fields` của project/type.
* Ghi dữ liệu: chỉ bảng mới của module.
* API: đăng ký route/representer trong module theo mẫu `type_schemes`/`field_rules`.
* Không patch contract hay schema representer (khác F02), vì screen không enforce.

## 12. Những thứ KHÔNG làm

* Không tạo model `Field` hoặc `Work Package` mới.
* Không implement workflow, transition screen, transition validator, automation, hành vi động giữa các field.
* Không enforce bằng screen (không chặn ghi theo screen).
* Không ghi vào `FormConfiguration`, không thay Form Configuration native, không sửa Angular native.
* Không cấu hình required/hidden/read-only/default (F02).
* Không đặt block activity/relations/hierarchy/bảng liên quan lên screen (Feature 04).

## 13. Câu hỏi mở (có mặc định, đổi được)

1. **Q1 — `transition` screen:** mặc định **hoãn** đến khi có Feature Workflow. Đổi nếu có yêu cầu kinh doanh cụ thể và người dùng.
2. **Q2 — Có đẩy screen xuống form native của OpenProject không?** Mặc định **không** (V1 chỉ phát qua API). Nếu cần, sẽ là một feature riêng với quyết định rõ về nguồn sự thật, vì ghi vào `FormConfiguration` sẽ ghi đè cấu hình native của admin.
3. **Q3 — Fallback `view → edit`:** mặc định **bật**; có thể đổi thành `view → native`.
4. **Q4 — Chặn lưu khi `required_not_placed`:** mặc định **chặn** (không thể tạo work package). Đổi thành cảnh báo nếu muốn linh hoạt.
5. **Q5 — Bên tiêu thụ đầu tiên:** mặc định là Feature 04 (Issue View). Nếu chưa có bên tiêu thụ nào khi release, V1 vẫn ship admin + API nhưng ghi rõ chưa có tác động lên UI người dùng.

## 14. User story và tiêu chí chấp nhận

**US-01 — Tạo screen.** Là admin, tôi tạo screen "Bug Create" thuộc ngữ cảnh create với các section và field theo thứ tự.
* Given screen mới, when thêm field `priority` hai lần, then lỗi `duplicate_field`.
* Given field key không tồn tại, then lỗi `unknown_field`.
* Given screen đã dùng trong scheme, when sửa, then hiện trang xác nhận nêu số scheme/project bị ảnh hưởng.

**US-02 — Sắp xếp.** Là admin, tôi đổi thứ tự section và field bằng kéo-thả hoặc bàn phím; thứ tự được lưu và đọc đúng ở resolver. Hoạt động khi tắt JS bằng ô số.

**US-03 — Screen Scheme.** Là admin, tôi gán cho mỗi Type một screen cho create/edit/view.
* Given screen context `edit`, when gán vào ô create, then lỗi `context_mismatch`.
* Given field `required` không có trên screen create, when lưu, then bị từ chối và liệt kê field thiếu (Q4).

**US-04 — Gán cho project.** Là quản lý project có quyền `assign_screen_scheme`, tôi gán scheme cho project và xem layout hiệu lực theo (type, ngữ cảnh) kèm nguồn `screen`/`native`.
* Given project chưa gán scheme, then nguồn là `native`.

**US-05 — Resolver.** Là frontend, tôi gọi `GET /api/v3/projects/:id/types/:type_id/screens/create` và nhận layout + trạng thái field + `diagnostics`.
* Field `hidden` theo F02 không xuất hiện trong sections.
* Fallback ngữ cảnh đúng thứ tự mục 0.2.4.
* Lỗi nội bộ resolver ⇒ vẫn trả 200 với `source: native` và có log.

**US-06 — Vòng đời.** Là admin, tôi deactivate screen/scheme; project dùng nó chuyển sang `native`; không có thao tác xoá khi đang dùng.

### Definition of Done

- [ ] Model + migration (đảo ngược được) + ràng buộc DB mục 4
- [ ] Registry `Screens::Fields` và validation field key
- [ ] `Screens::Resolver` + `diagnostics` + cache theo request + fail-open
- [ ] Tích hợp với `FieldRules::Resolver` khi module F02 bật; module vẫn chạy khi F02 tắt
- [ ] Screen/Section/Item CRUD + activate/deactivate + clone (admin UI và API v3)
- [ ] Screen Scheme + gán project + xem trước layout hiệu lực
- [ ] Kiểm tra xung đột mục 8 (từ chối / cảnh báo / diagnostics)
- [ ] Permission `assign_screen_scheme`; xác nhận không có quyền thì 403
- [ ] i18n đầy đủ; không có chuỗi hard-code; không có "jira" trong tên/route/menu
- [ ] Không modify file core; không thêm cột vào bảng core; không tạo model `Field`/`WorkPackage` mới
- [ ] Test: model, service, resolver, request spec API, feature spec admin UI (bao gồm bàn phím), a11y cơ bản
- [ ] Tài liệu admin + tài liệu API (OpenAPI)

## 15. Phụ thuộc và lộ trình

```text
01 Issue Type Scheme ──► 02 Field Rules ──► 03 Screen & Layout ──► 04 Issue View ──► 05 Navigator
```

* F03 chạy được khi F02 tắt (resolver bỏ qua phần `state`); khi F02 bật, trạng thái hiệu lực được ghép vào payload.
* F03 là điều kiện để Feature 04 có nguồn layout theo ngữ cảnh; Feature 04 sẽ quyết định các block không phải field và `width`.

Cắt lát đề xuất: **Slice 1** model + resolver + API đọc (có thể seed bằng console); **Slice 2** admin UI screen + scheme; **Slice 3** gán project + xem trước + chẩn đoán xung đột + cảnh báo tác động.
