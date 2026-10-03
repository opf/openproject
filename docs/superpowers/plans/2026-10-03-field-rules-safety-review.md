# Field Rules — Safety review (failure-mode & effects)

Ngày: 2026-10-03 · Chuyên gia: safety/QA · Chưa chạy được RSpec/Rails (Ruby 3.3.6 ≠ 4.0.7, không có Postgres): mọi kết luận dựa trên đọc code (HEAD `0bd650335`) và `ruby -c`. Các spec mới **chưa được chạy**. Spec đánh dấu `pending "KNOWN GAP (safety review #N)"` mô tả hành vi mong muốn mà code hiện tại (theo đọc code) chưa đạt; khi sửa xong RSpec sẽ báo "expected pending to fail" và cần bỏ dòng `pending`.

## Bất biến

- I1: một `(scheme, type)` có tối đa một item, một `(rule_set, field_key)` có tối đa một rule, một project có tối đa một scheme (unique index + validation).
- I2: không rule nào `hidden && required` hoặc `hidden && read_only` (chỉ validation model; **không có CHECK constraint**, `update_columns`/SQL thô phá được; `Repair` chữa).
- I3: không rule nào `required && read_only` thiếu default (chỉ validation model; **`Repair` không phát hiện**, xem #4).
- I4: rule set/scheme không bị xoá khi đang dùng (FK không cascade + `before_destroy`); xoá Type/Project cascade item/assignment.
- I5: tạo/sửa work package không bao giờ bị sập (500) bởi lỗi Resolver/patch (fail-open); nhưng **có thể bị khoá** (422 không tránh được) bởi tổ hợp rule hợp lệ về cú pháp (mục "Khoá người dùng").

## Bảng failure-mode

Trạng thái: **Mở** = chưa xử lý trong code; **Đã sửa** = đã được sửa bởi thành viên khác trong HEAD; **Spec** = có spec trong `modules/field_rules/spec`.

### Critical

Không có lỗi làm mất dữ liệu không thể phục hồi trong luồng tạo/sửa đơn lẻ. Khoá người dùng luôn phục hồi được bằng deactivate rule set/scheme (không xoá gì). Mức High bên dưới là ứng viên Critical nếu áp dụng cho Type phổ biến.

### High

| # | Tình huống | Hậu quả | Phục hồi | Trạng thái / đề xuất |
|---|---|---|---|---|
| 1 | `required` cho field mà project/người dùng không thể cung cấp: `category` khi project không có category; `target_versions` khi user thiếu `assign_versions`; `assignee` khi không có principal assignable; field nằm ngoài form configuration của Type (Layer 0 không hiển thị) | Mọi tạo WP của Type đó trả 422 mãi mãi (UI không có ô để điền). `Validator` chỉ kiểm `blank_value?`, không hỏi "field có khả dụng/ghi được cho user này không". CF không active thì an toàn (`respond_to?` false) | Deactivate rule set | **Mở.** Spec pending `lockout_and_compatibility_spec.rb` (category). Đề xuất: (a) `Validator.violations` bỏ qua field có `attribute` không nằm trong `contract.writable_attributes` (trừ khi default sẽ điền), (b) bỏ qua `category` khi `project.categories` rỗng, (c) UI cảnh báo trong form rule set và trang project settings ("N project không có category, rule bị bỏ qua") |
| 2 | Default không còn dùng được: priority bị deactivate, assignee không phải member/assignable/locked/bị xoá, (đã sửa: category khác project/đã xoá, CF đã xoá) | Với field `hidden`/`read_only` + default: người dùng không sửa được ⇒ mọi tạo WP lỗi (`only_active_priorities_allowed`, assignee không hợp lệ). `Fields.default_error` chỉ kiểm lúc **lưu** rule | Deactivate rule set | **Mở một phần.** Spec pending (priority inactive, assignee ngoài project); spec thường cho category/CF. Đề xuất: `Fields.apply_default` kiểm theo ngữ cảnh project (priority active, assignee thuộc `Principal.possible_assignee(project)`) và bỏ qua default không dùng được như đã làm cho category |
| 3 | Copy project (`WorkPackages::CopyService` cắt attribute theo `writable_attributes` của WP **nguồn**) khi nguồn thuộc project có rule `hidden`/`read_only` | Giá trị hidden/read-only (ví dụ `estimated_time`) **bị mất âm thầm** ở bản sao, trái với "giữ nguyên trạng thái" của `CopyProjectContract`. Mất dữ liệu ở bản sao, nguồn không đổi | Copy lại sau khi deactivate rule set | **Mở.** Spec pending. Đề xuất: `ContractPatch#writable_attributes` trả `super` khi contract là `CopyProjectContract` (hoặc `include WorkPackages::SkipAuthorizationChecks`); rule của project đích vẫn được áp khi validate bản sao |
| 7 | Rule `hidden` (hoặc `read_only` không default) cho CF đã `is_required` trong cấu hình CF/variant (Layer 0 required) | Core đòi giá trị, rule cấm ghi ⇒ không tạo được WP. Model chỉ kiểm tổ hợp trong chính rule | Deactivate | **Mở.** Spec pending. Đề xuất: `FieldRule` validate không cho hidden/read_only (không default) trên CF/field required native; Resolver bỏ qua hidden khi native required; UI đã đánh dấu CF required nhưng chưa chặn |

### Medium

| # | Tình huống | Hậu quả | Phục hồi | Trạng thái / đề xuất |
|---|---|---|---|---|
| 4 | `Repair` chỉ tìm `hidden+required`, `hidden+read_only` và rule của CF đã xoá | `required+read_only` không default (đặt bằng SQL/import/API cũ) và default trỏ bản ghi không còn không được báo; `field_key` không còn trong allowlist (module gỡ) cũng không | Sửa tay | **Mở.** Spec pending (`invariants_spec`). Đề xuất: thêm vào dry-run báo cáo: required+read_only không default, `field_key` ngoài registry, default không hợp lệ (chỉ báo, không xoá) |
| 8 | Tích hợp tạo WP bằng user thật: incoming email (`IncomingEmails::Handlers::WorkPackage`), MCP tools, `Projects::CreationWizard::CreateArtifactWorkPackageService` (Type do project chọn) | Email bị từ chối / wizard gửi yêu cầu thất bại khi Type có required không thể suy ra (create không có grandfather); thông điệp chỉ ở log/phản hồi | Điền rule hoặc bỏ rule cho Type đó | Chấp nhận theo thiết kế (§0.2.4). Đề xuất: tài liệu hoá; wizard nên hiện lỗi 422 cho user; cân nhắc `system_update`/actor `:system` cho wizard |
| 9 | Primer create dialog (`WorkPackages::Dialogs::CreateForm`, dùng cho "create child") chỉ hiện subject, description và CF required **native**; không hiện field required do rule | Rule `required assignee/category/due_date` ⇒ dialog 422, user không điền được trong dialog (full form Angular dùng được) | Mở full form | **Mở** (chuyên gia UI). Đề xuất: dialog render thêm field required theo `Resolver`, hoặc nút "mở form đầy đủ" khi 422 |
| 10 | Nhiều module cùng `add_constraint` một attribute: callable đăng ký **sau** ghi đè bản bọc của Field Rules (thứ tự `to_prepare`/load engine); dev reload gọi `install` lặp (bọc lồng nhau, đúng nhưng chậm dần) | Hidden không còn hiệu lực trong form (schema/contract vẫn chặn ghi vì cơ chế riêng) | Khởi động lại | **Mở**, Spec `patches_fail_open_spec.rb` ghi lại hành vi. Đề xuất: không lồng khi `existing` đã là wrapper của module (đánh dấu lambda), hoặc áp hidden ở lớp contract/schema thay vì chỉ constraint |
| 11 | Hai admin sửa cùng rule set/scheme | Last-writer-wins (form gửi toàn bộ danh sách); `lock!` chỉ tuần tự hoá, không phát hiện cũ. Clone song song: `RecordNotUnique` do `clone_name` check-then-insert không được rescue ở `clone` ⇒ 500. `SchemeService.assign` retry 2 lần rồi raise ⇒ 500. `toggle`/`impact`/confirm không khoá (TOCTOU nhỏ) | Tải lại, sửa lại | **Mở**, Spec ghi lại. Đề xuất: `lock_version`/so `updated_at` truyền từ form (409/validation), rescue `RecordNotUnique` trong `clone`/`assign` |
| 12 | Nâng core: guard chỉ kiểm tên method (`method_defined?`), không kiểm chữ ký; `SchemaPatch#json_key_dependencies` ghi đè method private của `API::Caching::CachedRepresenter` nhưng **không** nằm trong `PATCH_TARGETS`; hàm này gọi Resolver ngoài `rescue` | Đổi tên `json_key_dependencies` ⇒ `super` NoMethodError ở mọi schema API (500) mà boot không báo | Sửa module | **Mở.** Spec pending (meta-spec "mọi method override phải có trong PATCH_TARGETS"). Đề xuất: thêm `json_key_dependencies` vào guard, bọc phần mở rộng key bằng rescue trả `super` |

### Low

| # | Tình huống | Hậu quả | Trạng thái / đề xuất |
|---|---|---|---|
| 5 | (đã sửa) `SchemaPatch#to_json` rescue bao cả `super` ⇒ lỗi core thành body `nil` | — | **Đã sửa** trong HEAD; spec thường "does not swallow an error raised by the core serialisation" |
| 6 | (đã sửa) một default lỗi (CF đã xoá) dừng toàn vòng default | — | **Đã sửa** (`apply_field_rule_default` rescue theo field + bỏ qua CF không khả dụng); spec thường |
| 13 | `rescue StandardError` trong `Resolver.for`/`Validator`/`SetAttributesService` khi giao dịch PG đã aborted | Rescue nuốt lỗi nhưng truy vấn kế tiếp của core ném `InFailedSqlTransaction`: không ghi nửa chừng, lỗi hiện ở chỗ khác (khó chẩn đoán). Resolver không cache kết quả lỗi | Chấp nhận; spec `patches_fail_open_spec.rb` ghi lại. Đề xuất log kèm correlation/tăng bộ đếm thay vì chỉ `Rails.logger.error` |
| 14 | Xoá Type: cascade item đúng nhưng cache `RequestStore` cũ trong cùng request (như F01 #10) | Hết request | Đề xuất `Type.after_destroy_commit` reset cache (ngoài phạm vi module nếu không patch core) |
| 15 | Xoá custom field | Rule mồ côi vẫn nằm, bị bỏ qua an toàn (`respond_to?` false; default được bỏ qua) | Spec; `field_rules:repair` dọn |
| 16 | Console/job: cache `RequestStore` (`SharedJobSetup#with_clean_request_store` cho job; console thì không) | Cấu hình cũ khi sửa bằng `update_all` | Spec ghi lại; trong console gọi `FieldRules::Resolver.reset_cache` hoặc `RequestStore.clear!` |
| 17 | Gỡ module | Quyền `assign_field_rule_scheme` còn trong role, bảng còn nếu không `migrate:down` (vô hại: không còn patch nào đọc) | Runbook trong README |
| 18 | Rollback migration | Mất toàn bộ rule set/scheme/assignment | Backup; spec `rollback_with_data_spec.rb` (core data không đổi, tái migrate rỗng) |
| 19 | Migration chạy lại | `create_table` không `if_not_exists`: nếu tay xoá `schema_migrations` mà bảng còn ⇒ lỗi `PG::DuplicateTable` (dừng, không phá dữ liệu) | Chấp nhận |
| 20 | Rule trên field/CF trong project không khả dụng, Type chưa gán scheme, scheme inactive vẫn gán | Bị bỏ qua (native) | Spec `invariants_spec.rb` |
| 21 | Dependents của scheduling/ancestors/descendants | Lưu `validate: false` / `UpdateDependentContract#validate => true` ⇒ không bao giờ bị required/read-only chặn, kể cả `enforce_on_update` | Spec ghi lại |
| 22 | Client API cũ gặp required mới | 422 `required_by_field_rules` kèm tên Type; schema API có `required: true` | Chấp nhận (create); update được grandfather |

## Khoá người dùng: đánh giá tổ hợp

| Tổ hợp | Kết quả | Ghi chú |
|---|---|---|
| required + hidden | Bị chặn khi lưu rule | Tốt |
| required + read_only, không default | Bị chặn khi lưu rule | Nhưng SQL/API cũ có thể tạo ra, `Repair` chưa phát hiện (#4) |
| required + read_only + default hợp lệ | Tạo được (default điền bởi hệ thống trong `change_by_system`) | Spec |
| required + read_only + default **hết hợp lệ** | Khoá (#2) | Cần kiểm lúc áp default |
| hidden + default **hết hợp lệ** | Khoá (#2) | tương tự |
| required cho field project không có (category) | Khoá (#1) | Giảm: bỏ qua khi không khả dụng + cảnh báo UI |
| required cho CF không active trong project/type | Không khoá | `respond_to?` false |
| hidden/read_only cho field native-required | Khoá (#7) | |
| required cho field user không ghi được (quyền) | Khoá (#1) | Giảm: chỉ đòi field nằm trong `writable_attributes` |

Đề xuất giảm thiểu chung: một hàm `Fields.available_for?(work_package, key, user)` dùng ở 3 nơi (Validator, apply_default, UI cảnh báo) để "rule không khả dụng ⇒ bỏ qua và báo".

## Fail-open vs fail-closed

- Fail-open (đã đúng): `Resolver.for`, `ContractPatch#field_rules_configuration`, `#add_field_rule_errors`, `Constraints.hidden?`, `SchemaPatch#adjust_schema_json`, `apply_field_rule_default` (theo từng field). Lỗi ⇒ log + hành vi native.
- Fail-closed (cố ý): hết. Rule làm sai không bị chặn ở contract nếu resolver lỗi: **kiểm soát bị bỏ qua âm thầm** (chỉ log). Đề xuất bộ đếm/cảnh báo trong admin.
- Không rescue được: lỗi DB làm transaction aborted (#13), `NoMethodError` do `super` không còn (boot guard #12).

## Tương thích

| Luồng | Hành vi |
|---|---|
| Scheduling, ancestors, descendants | Không bị chặn (#21); actor `:system` chỉ cho `SystemUser` |
| Bulk edit | Từng WP qua `UpdateService`: grandfather; lỗi theo từng WP |
| Move WP sang project khác | Rule project đích áp (project đổi ⇒ kiểm required) — spec |
| Copy WP / copy project | #3 |
| Email, MCP, wizard | #8 |
| Import | Không có importer WP trong core; nếu có dùng user thật ⇒ như email |
| Hidden CF/native | Dữ liệu giữ nguyên, không bị báo thay đổi — spec |
| Module không cài | Không có patch nào, native |
| Dev reload | `to_prepare` prepend mỗi lần trên lớp mới (spec đếm đúng 1); `Constraints.install` có thể lồng (#10) |

## Spec đã thêm (chưa chạy)

- `spec/db/invariants_spec.rb`: ràng buộc DB, xoá Type/Project, deactivate khi đang dùng, CF đã xoá/không active, Repair, đồng thời (conflict, lock, last-writer-wins).
- `spec/db/rollback_with_data_spec.rb`: rollback có dữ liệu, core không đổi, tái migrate rỗng, index/FK.
- `spec/lib/open_project/field_rules/patches_fail_open_spec.rb`: SchemaPatch, Constraints, boot guard, prepend một lần, transaction aborted, cache request.
- `spec/lib/open_project/field_rules/lockout_and_compatibility_spec.rb`: khoá người dùng (có pending cho #1, #2, #3, #7), fail-open hợp đồng, system/dependent, grandfather, copy.

## Việc còn lại cho chuyên gia khác

- Backend: #1, #2, #3, #4, #7, #11, #12 (xem cột đề xuất).
- UI/UX: cảnh báo field không khả dụng (#1), dialog create child (#9), cảnh báo form cũ (xung đột `lock_version`).
- Core/hạ tầng: CHECK constraint DB cho I2/I3 (migration mới, không sửa migration đã chạy), hook xoá Type/CF reset cache.
