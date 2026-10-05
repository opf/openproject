# Type Scheme — Safety review (failure-mode & effects)

Ngày: 2026-10-03 · Chuyên gia: safety · Chưa chạy được RSpec/Rails (Ruby 3.3.6, không có Postgres): mọi kết luận dựa trên đọc code và `ruby -c`.

## Bất biến

- I1: đúng một Default Scheme active (`is_default` partial unique index + validation `default_scheme_stays_active`).
- I2: mỗi scheme active có đúng một item default (partial unique index chặn >1; validation chặn 0 khi save; **không có gì chặn 0 do cascade**).
- I3: mỗi project resolve được một scheme (`Resolver` fallback Default Scheme; `nil` chỉ khi chưa có scheme nào).
- I4: tạo/sửa WP không bao giờ bị khoá bởi scheme rỗng/lỗi (fail-open sang `enabled_types`).

## Bảng failure-mode

| # | Mức | Tình huống | Hậu quả | Phục hồi hiện có | Việc đã làm / đề xuất |
|---|---|---|---|---|---|
| 1 | High | Xoá Type (cascade `type_scheme_items`) trúng item default, ví dụ Task | Scheme active không có default (I2 vỡ). Tạo WP vẫn chạy (lấy item đầu theo position). `PATCH` chỉ đổi tên thất bại vì `exactly_one_default`; `DefaultScheme.add_type` thêm item không default nên không tự lành | Không | Đã thêm `TypeSchemes::Repair` + `rake type_schemes:repair` (dry-run mặc định). Đề xuất: `Type.after_destroy_commit` gọi lành lặn nhẹ (xem #10) |
| 2 | High | `PROJECT_CREATED` listener ném lỗi (DB, validation) | Exception lan ra `notify_project_created`, làm hỏng tạo project dù Resolver đã có fallback | Không | Đã sửa: `project_created_listener.rb` rescue `StandardError` + log; project không có assignment vẫn resolve Default Scheme, `type_schemes:repair` gán lại |
| 3 | High | Core đổi tên/ký hiệu `assignable_types`, `validate_enabled_type`, `assign_default_type` | `super` ném `NoMethodError` ở mọi lần tạo/sửa WP (outage) | Chỉ spec | Đã thêm `spec/db/invariants_spec.rb` (guard hook). Đề xuất (engine): kiểm tra `method_defined?`/`private_method_defined?` trong `to_prepare` và `raise` lúc boot |
| 4 | High | Lỗi logic trong `ContractPatch`/`SetAttributesServicePatch` (scheme hỏng, nil) | 500 trên mọi form/API WP | Không | Đề xuất (contract_patch, set_attributes_service_patch): bọc phần scheme trong `rescue StandardError`, log và trả `super`. Lưu ý: lỗi PG trong transaction đang mở không rescue được |
| 5 | Medium | `Type.after_create_commit { add_type }` ném lỗi | Tạo Type trả 500 dù đã commit; Type vắng trong Default Scheme | `Repair` thêm Type thiếu | Đề xuất: rescue + log trong hook; `add_type` nên đặt `is_default: true` khi scheme chưa có item default |
| 6 | Medium | Đổi Default Scheme đồng thời (hai admin) | `RecordNotUnique` từ `idx_type_scheme_one_default` thành 500 | Rollback transaction, dữ liệu nguyên vẹn | Đề xuất (scheme_service): rescue `RecordNotUnique` trong `save` và trả lỗi dễ hiểu |
| 7 | Medium | Rollback chỉ `20261002100000` | Phiên bản seed `20261003100000` còn trong `schema_migrations`, up lại không seed | `Repair` tạo lại Default Scheme và gán project | Đã sửa tài liệu: rollback cả hai migration theo thứ tự; thêm runbook |
| 8 | Medium | Migration seed trên DB lớn | `DefaultMigration` gán từng project trong một transaction dài (nhiều query/project); dry-run in tên mọi project | Idempotent, lỗi giữa chừng rollback toàn bộ | Đề xuất (default_migration, perf): `insert_all` theo lô + `ON CONFLICT DO NOTHING`, chỉ in số lượng. `Repair` đã dùng cách này |
| 9 | Medium | Tạo WP có Type chỉ định bởi tích hợp nội bộ/mail/import/copy WP sang project khác (Type ngoài scheme) | `not_in_scheme` 422 thay vì tạo được; WP đã tồn tại không bị đổi | Cố ý theo spec; Default Scheme chứa mọi Type | Ghi nhận; admin cần giữ Type tích hợp (BIM, backlogs) trong scheme. Cân nhắc cho phép bỏ qua cho import hệ thống |
| 10 | Low | Xoá Type không qua cascade callbacks nên không reset cache | Cache request cũ trong cùng request | Hết request | Đề xuất `Type.after_destroy_commit { TypeSchemes::Resolver.reset_cache }` |
| 11 | Low | Console/job dài: cache `RequestStore` | Scheme cũ trong tiến trình sống lâu; job được `with_clean_request_store`, console thì không | Model callbacks reset cùng tiến trình | Chấp nhận; trong console gọi `TypeSchemes::Resolver.reset_cache` |
| 12 | Low | `update_columns`/SQL thô, console | Phá I1-I3 | Bảng #1 + `Repair` + partial unique index | Đã có spec `spec/db/invariants_spec.rb` mô tả hành vi fail-open và phục hồi |
| 13 | Low | Copy project | Project mới nhận Default Scheme, không kế thừa scheme của nguồn (copy dùng `PROJECT_CREATED`) | Admin gán lại | Ghi nhận |
| 14 | Low | Archive project, xoá project | Assignment giữ nguyên / cascade theo FK | OK | Spec FK |
| 15 | Low | Kéo-thả chưa lưu | Rời trang mất thứ tự chưa Save; không có cảnh báo `beforeunload` | Ô `position` vẫn sửa được khi tắt JS | Đề xuất cho UI/UX: cảnh báo thay đổi chưa lưu |
| 16 | Low | Gỡ module | Chỉ bỏ 3 bảng; quyền `assign_type_scheme` còn trong role | Doc runbook | Đã ghi tài liệu |

## Concurrency & idempotency

- `DefaultScheme.ensure!`: hai tiến trình cùng tạo → một thắng, bên kia gặp `RecordNotUnique` (unique name hoặc partial index) bên trong savepoint của `SchemeService.save`, rescue và đọc lại `current`. An toàn trong transaction ngoài.
- Thứ tự khoá: `save` khoá scheme rồi `update_all` các scheme default khác; `deactivate` khoá scheme rồi cập nhật assignment. Không thấy chu trình khoá giữa hai thao tác khác loại. Hai lần đổi default đồng thời có thể thua bởi unique index (#6).
- `Repair`: một transaction, `pg_advisory_xact_lock`, chỉ ghi khi `dry_run: false`, chạy lại không thay đổi gì.
- Migration seed chạy hai lần: idempotent (`ensure!` + chỉ project chưa có assignment).

## Spec đã thêm (chưa chạy)

- `spec/db/invariants_spec.rb`: ràng buộc DB, guard model, fail-open khi vỡ bất biến, phục hồi, guard hook prepend.
- `spec/services/type_schemes/repair_spec.rb`, `spec/tasks/type_schemes_repair_rake_spec.rb`.
