# Type Scheme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cho phép Admin định nghĩa Type Scheme và gán cho Project để giới hạn (và sắp thứ tự, đặt default) Type khi tạo Work Package mới, không động tới dữ liệu có sẵn.

**Architecture:** Module Rails engine mới `modules/type_schemes` (mẫu: `modules/job_status`). 3 bảng `type_schemes`, `type_scheme_items`, `project_type_schemes` tham chiếu `types`/`projects`. `TypeSchemes::Resolver` là nguồn sự thật; một `prepend` duy nhất vào `WorkPackages::BaseContract` lọc `assignable_types` và validate khi tạo/đổi Type. Scheme là lớp lọc riêng, **không** đồng bộ vào `project_types` (vì `Projects::Types::RemoveService` chặn gỡ Type đang có WP).

**Tech Stack:** Rails 8.1, RSpec, Primer ViewComponent + Turbo, Grape API v3, Angular (chỉ kiểm tra, không sửa).

**Spec:** [docs/superpowers/specs/2026-10-02-type-scheme-design.md](../specs/2026-10-02-type-scheme-design.md)

## Global Constraints

- Không sửa file core: chỉ thêm file trong `modules/type_schemes/`, `Gemfile.modules` (một dòng), `docs/`.
- Chỉ một điểm chạm vào core qua `prepend` trong `config.to_prepare`: `WorkPackages::BaseContract`.
- Tên bảng giữ nguyên: `type_schemes`, `type_scheme_items`, `project_type_schemes`.
- `UNIQUE(project_id)` trên `project_type_schemes`; `UNIQUE(scheme_id, type_id)` trên items; tối đa 1 scheme `is_default`; đúng 1 item `is_default` mỗi scheme active.
- Project không có scheme (hoặc scheme inactive) ⇒ hành vi native, không lọc.
- WP có sẵn không bao giờ bị đổi Type; Type hiện tại của WP luôn nằm trong allowed types của chính nó.
- Manage Scheme = admin; `assign_type_scheme` là project permission.
- Mọi chuỗi UI qua i18n (`modules/type_schemes/config/locales/en.yml`).
- Header license `#-- copyright ... #++` như các file khác trong repo.
- Chạy test: `bundle exec rspec <path>`.

## File Structure

```text
modules/type_schemes/
  openproject-type_schemes.gemspec
  lib/openproject-type_schemes.rb
  lib/open_project/type_schemes.rb
  lib/open_project/type_schemes/engine.rb        # register, menu, permission, api, hook, event
  lib/open_project/type_schemes/contract_patch.rb# prepend vào BaseContract
  db/migrate/20261002100000_create_type_schemes.rb
  app/models/type_scheme.rb
  app/models/type_scheme_item.rb
  app/models/project_type_scheme.rb
  app/services/type_schemes/resolver.rb
  app/services/type_schemes/scheme_service.rb    # create/update/clone/deactivate/assign/unassign/destroy
  app/controllers/admin/type_schemes_controller.rb
  app/controllers/projects/settings/type_scheme_controller.rb
  app/views/... (admin index/form, project settings show)
  lib/api/v3/type_schemes/*.rb
  lib/tasks/type_schemes.rake                    # migrate:dry_run/auto
  config/locales/en.yml
  spec/**
Gemfile.modules                                         # + 1 dòng
```

---

### Task 1: Module skeleton, migration, models

**Files:**
- Create: `modules/type_schemes/openproject-type_schemes.gemspec`, `lib/openproject-type_schemes.rb`, `lib/open_project/type_schemes.rb`, `lib/open_project/type_schemes/engine.rb`
- Create: `db/migrate/20261002100000_create_type_schemes.rb`, `app/models/type_scheme.rb`, `app/models/type_scheme_item.rb`, `app/models/project_type_scheme.rb`
- Modify: `Gemfile.modules` (thêm `gem 'openproject-type_schemes', path: 'modules/type_schemes'` cạnh `openproject-job_status`)
- Test: `modules/type_schemes/spec/models/type_scheme_spec.rb`, `spec/factories/type_scheme_factory.rb`

**Interfaces:**
- Produces: `TypeScheme` (`has_many :items` ordered by position, `has_many :project_assignments`, `#types`, `#default_type`, `#default_item`), `TypeSchemeItem(scheme_id, type_id, position, is_default)`, `ProjectTypeScheme(project_id, scheme_id)`; factory `:type_scheme`.

- [ ] **Step 1: Sao chép khung từ job_status**

Mở `modules/job_status/openproject-job_status.gemspec`, `lib/openproject-job_status.rb`, `lib/open_project/job_status.rb`, `lib/open_project/job_status/engine.rb`; tạo bản tương ứng với tên `type_schemes`. Engine tối thiểu:

```ruby
module OpenProject::TypeSchemes
  class Engine < ::Rails::Engine
    engine_name :openproject_type_schemes

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-type_schemes",
             author_url: "https://www.openproject.org",
             bundled: true
  end
end
```

Thêm gem vào `Gemfile.modules`, chạy `bundle install`.
Expected: bundle thành công, `bundle exec rails runner 'puts OpenProject::TypeSchemes::Engine'` in tên class.

- [ ] **Step 2: Viết spec model (fail)**

```ruby
# spec/models/type_scheme_spec.rb
require "spec_helper"

RSpec.describe TypeScheme do
  let(:epic)  { create(:type, name: "Epic") }
  let(:story) { create(:type, name: "Story") }

  def build_scheme(items)
    described_class.new(name: "Dev").tap do |scheme|
      items.each_with_index do |(type, default), i|
        scheme.items.build(type:, position: i + 1, is_default: default)
      end
    end
  end

  it "requires a name" do
    expect(described_class.new).not_to be_valid
  end

  it "rejects duplicate types" do
    expect(build_scheme([[epic, true], [epic, false]])).not_to be_valid
  end

  it "requires exactly one default item when active" do
    expect(build_scheme([[epic, false], [story, false]])).not_to be_valid
    expect(build_scheme([[epic, true], [story, true]])).not_to be_valid
    expect(build_scheme([[epic, false], [story, true]])).to be_valid
  end

  it "exposes ordered types and default type" do
    scheme = build_scheme([[epic, false], [story, true]]).tap(&:save!)
    expect(scheme.types).to eq([epic, story])
    expect(scheme.default_type).to eq(story)
  end

  it "allows only one default scheme" do
    create(:type_scheme, is_default: true)
    expect(build(:type_scheme, is_default: true)).not_to be_valid
  end
end
```

Factory:

```ruby
FactoryBot.define do
  factory :type_scheme do
    sequence(:name) { |n| "Scheme #{n}" }
    active { true }
    is_default { false }
    transient { types { [create(:type)] } }
    after(:build) do |scheme, ev|
      ev.types.each_with_index do |t, i|
        scheme.items.build(type: t, position: i + 1, is_default: i.zero?)
      end
    end
  end
end
```

Run: `bundle exec rspec modules/type_schemes/spec/models` → FAIL (uninitialized constant).

- [ ] **Step 3: Migration**

```ruby
class CreateTypeSchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :type_schemes do |t|
      t.string  :name, null: false, index: { unique: true }
      t.text    :description
      t.boolean :is_default, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :type_schemes, :is_default, unique: true, where: "is_default", name: "idx_type_scheme_one_default"

    create_table :type_scheme_items do |t|
      t.references :scheme, null: false, foreign_key: { to_table: :type_schemes, on_delete: :cascade }
      t.references :type,   null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.boolean :is_default, null: false, default: false
      t.timestamps
      t.index %i[scheme_id type_id], unique: true
      t.index :scheme_id, unique: true, where: "is_default", name: "idx_type_scheme_item_one_default"
    end

    create_table :project_type_schemes do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :scheme,  null: false, foreign_key: { to_table: :type_schemes }
      t.timestamps
    end
  end
end
```

Run: `bundle exec rails db:migrate && bundle exec rails db:migrate:redo`. Expected: up/down ok. (Nếu `redo` lỗi do `scheme` FK không cascade khi xoá scheme có project: đúng chủ ý, guard nằm ở service.)

- [ ] **Step 4: Models**

```ruby
class TypeScheme < ApplicationRecord
  self.table_name = "type_schemes"

  has_many :items, -> { order(:position) }, class_name: "TypeSchemeItem",
           foreign_key: :scheme_id, inverse_of: :scheme, dependent: :destroy
  has_many :project_assignments, class_name: "ProjectTypeScheme", foreign_key: :scheme_id,
           inverse_of: :scheme, dependent: :restrict_with_error
  has_many :projects, through: :project_assignments

  validates :name, presence: true, uniqueness: true
  validates :is_default, uniqueness: true, if: :is_default
  validate :types_unique
  validate :exactly_one_default_item, if: :active

  scope :active, -> { where(active: true) }

  def types = items.sort_by(&:position).map(&:type)
  def default_item = items.find(&:is_default)
  def default_type = default_item&.type

  private

  def types_unique
    ids = items.reject(&:marked_for_destruction?).map(&:type_id)
    errors.add(:items, :taken) if ids.uniq.size != ids.size
  end

  def exactly_one_default_item
    live = items.reject(&:marked_for_destruction?)
    errors.add(:items, :exactly_one_default) unless live.count(&:is_default) == 1
  end
end

class TypeSchemeItem < ApplicationRecord
  self.table_name = "type_scheme_items"
  belongs_to :scheme, class_name: "TypeScheme", inverse_of: :items
  belongs_to :type
end

class ProjectTypeScheme < ApplicationRecord
  self.table_name = "project_type_schemes"
  belongs_to :project
  belongs_to :scheme, class_name: "TypeScheme", inverse_of: :project_assignments
  validates :project_id, uniqueness: true
  validate { errors.add(:scheme, :inactive) unless scheme&.active }
end
```

Thêm key i18n `activerecord.errors.models.type_scheme.attributes.items.exactly_one_default` vào `config/locales/en.yml` của module.

- [ ] **Step 5: Run & commit**

Run: `bundle exec rspec modules/type_schemes/spec/models` → PASS.

```bash
git add modules/type_schemes Gemfile.modules Gemfile.lock
git commit -m "feat(type-schemes): module skeleton, tables and models"
```

---

### Task 2: Resolver

**Files:**
- Create: `app/services/type_schemes/resolver.rb`
- Test: `spec/services/type_schemes/resolver_spec.rb`

**Interfaces:**
- Consumes: Task 1 models.
- Produces: `TypeSchemes::Resolver.for_project(project) → TypeScheme | nil` (nil khi không gán hoặc scheme inactive); `Resolver.allowed_types(project, scope = project.enabled_types) → ActiveRecord::Relation | Array<Type>` sắp theo scheme, giao với `scope`; trả lại `scope` nguyên trạng khi không có scheme hoặc giao rỗng.

- [ ] **Step 1: Test (fail)**

```ruby
require "spec_helper"

RSpec.describe TypeSchemes::Resolver do
  let(:project) { create(:project, types: [epic, story, bug]) }
  let(:epic)  { create(:type, name: "Epic") }
  let(:story) { create(:type, name: "Story") }
  let(:bug)   { create(:type, name: "Bug") }

  it "returns nil and native types without a scheme" do
    expect(described_class.for_project(project)).to be_nil
    expect(described_class.allowed_types(project)).to match_array([epic, story, bug])
  end

  context "with an assigned scheme [story*, epic]" do
    before do
      scheme = create(:type_scheme, types: [story, epic])
      ProjectTypeScheme.create!(project:, scheme:)
    end

    it "filters, orders and puts default first" do
      expect(described_class.allowed_types(project).to_a).to eq([story, epic])
    end

    it "falls back to native types when scheme types are not enabled in the project" do
      other = create(:project, types: [bug])
      ProjectTypeScheme.create!(project: other, scheme: TypeScheme.last)
      expect(described_class.allowed_types(other).to_a).to eq([bug])
    end

    it "ignores inactive schemes" do
      TypeScheme.last.update_columns(active: false)
      expect(described_class.for_project(project)).to be_nil
    end
  end
end
```

Run → FAIL.

- [ ] **Step 2: Implement**

```ruby
module TypeSchemes
  module Resolver
    module_function

    def for_project(project)
      return if project.nil?

      ProjectTypeScheme.includes(scheme: { items: :type }).find_by(project_id: project.id)
                            &.scheme&.then { |s| s if s.active }
    end

    # Returns +scope+ untouched when no scheme applies, so project settings stay native.
    def allowed_types(project, scope = project.enabled_types)
      scheme = for_project(project)
      return scope unless scheme

      by_id = scope.index_by(&:id)
      ordered = scheme.items.sort_by { |i| [i.is_default ? 0 : 1, i.position] }
                      .filter_map { |i| by_id[i.type_id] }
      ordered.presence || scope
    end
  end
end
```

Note: `allowed_types` trả Array khi có scheme; contract patch (Task 3) phải chấp nhận cả relation và array.

- [ ] **Step 3: Run & commit** — `bundle exec rspec modules/type_schemes/spec/services/type_schemes/resolver_spec.rb` → PASS.

```bash
git add modules/type_schemes && git commit -m "feat(type-schemes): resolver"
```

---

### Task 3: Hook vào WorkPackages::BaseContract (spike + implement)

**Files:**
- Create: `lib/open_project/type_schemes/contract_patch.rb`
- Modify: `lib/open_project/type_schemes/engine.rb` (thêm `config.to_prepare`)
- Test: `spec/contracts/work_packages/scheme_filtering_spec.rb`, `spec/requests/api/v3/work_package_form_scheme_spec.rb`

**Interfaces:**
- Consumes: `Resolver.allowed_types`.
- Produces: `assignable_types` đã lọc; lỗi `errors.add :type_id, :not_in_scheme` khi tạo mới hoặc đổi Type sang Type ngoài scheme.

- [ ] **Step 1: Spike (bắt buộc, ghi kết quả vào spec doc mục 10)**

Xác minh bằng cách đọc `frontend/src/app/features/work-packages/components/wp-new/wp-create.component.ts` và `wp-create.service.ts` cách chọn Type mặc định khi không có `?type=`: dùng phần tử đầu `allowedValues` của schema hay `Type.position`? Ghi kết quả: nếu theo allowedValues ⇒ default hoạt động end-to-end; nếu không ⇒ ghi giới hạn vào spec §10 và docs, không sửa Angular.

- [ ] **Step 2: Test contract (fail)**

```ruby
require "spec_helper"

RSpec.describe WorkPackages::CreateContract, "scheme filtering" do
  let(:epic)  { create(:type) }
  let(:story) { create(:type) }
  let(:bug)   { create(:type) }
  let(:project) { create(:project, types: [epic, story, bug]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] }) }

  before do
    ProjectTypeScheme.create!(project:, scheme: create(:type_scheme, types: [story, epic]))
  end

  def contract_for(wp) = described_class.new(wp, user)

  it "limits assignable types, default first" do
    wp = build(:work_package, project:, type: story)
    expect(contract_for(wp).assignable_types.to_a).to eq([story, epic])
  end

  it "rejects a new work package with a type outside the scheme" do
    wp = build(:work_package, project:, type: bug, author: user)
    contract = contract_for(wp)
    expect(contract).not_to be_valid
    expect(contract.errors.symbols_for(:type_id)).to include(:not_in_scheme)
  end

  it "keeps existing work packages editable and keeps their own type allowed" do
    wp = create(:work_package, project:, type: bug)
    wp.subject = "changed"
    c = WorkPackages::UpdateContract.new(wp, user)
    expect(c.assignable_types.to_a).to include(bug)
    c.validate
    expect(c.errors.symbols_for(:type_id)).not_to include(:not_in_scheme)
  end
end
```

Run → FAIL.

- [ ] **Step 3: Implement patch**

```ruby
module OpenProject::TypeSchemes
  module ContractPatch
    def assignable_types
      scope = super
      allowed = ::TypeSchemes::Resolver.allowed_types(model.project, scope)
      return scope if allowed.equal?(scope)

      allowed = allowed.to_a
      current = model.type_id_was && scope.find { |t| t.id == model.type_id_was }
      allowed << current if current && allowed.exclude?(current)
      allowed
    end

    private

    def validate_enabled_type
      super
      return unless model.project && type_context_changed?
      return if ::TypeSchemes::Resolver.for_project(model.project).nil?

      unless assignable_types.map(&:id).include?(model.type_id)
        errors.add :type_id, :not_in_scheme
      end
    end
  end
end
```

Engine:

```ruby
config.to_prepare do
  ::WorkPackages::BaseContract.prepend(OpenProject::TypeSchemes::ContractPatch)
end
```

Lưu ý: `assignable_types` ở core gọi `.includes(:color)` trên relation; `allowed` trả Array nên caller phải tương thích — kiểm tra mọi caller bằng `rg "assignable_types"` (đã có: `specific_work_package_schema.rb:54`, `dialogs/create_form.rb:65`, `dialogs/creation.rb:71`) và nếu một caller cần Relation thì đổi patch trả `Type.where(id: ids).in_order_of(:id, ids)`. Thêm i18n `activerecord.errors.models.work_package.attributes.type_id.not_in_scheme`.

- [ ] **Step 4: Request spec cho API v3**

Gọi `POST /api/v3/work_packages/form` (payload `_links.type` = bug) trên project có scheme; expect `errors.type` có mặt; GET schema `…/schemas/:project-:type` có `type.allowedValues` chỉ gồm `story, epic`. Tham khảo `spec/requests/api/v3/work_packages/` cho cách dựng.

- [ ] **Step 5: Run & commit**

Run: `bundle exec rspec modules/type_schemes/spec/contracts modules/type_schemes/spec/requests` và regression `bundle exec rspec spec/contracts/work_packages` → PASS.

```bash
git add modules/type_schemes && git commit -m "feat(type-schemes): filter assignable work package types by scheme"
```

---

### Task 4: SchemeService (create/update/clone/deactivate/assign/unassign/destroy)

**Files:**
- Create: `app/services/type_schemes/scheme_service.rb`
- Test: `spec/services/type_schemes/scheme_service_spec.rb`

**Interfaces:**
- Produces (đều trả `ServiceResult`): `SchemeService.create(params)`, `.update(scheme, params)`, `.clone(scheme)`, `.deactivate(scheme)`, `.destroy(scheme)` (fail `:assigned_to_projects` kèm danh sách project), `.assign(project, scheme)`, `.unassign(project)`, `.impact(scheme, removed_type_ids:) → { project_count:, work_package_counts: { type_id => n } }` cho cảnh báo UI.
- `params`: `{ name:, description:, items: [{ type_id:, position:, is_default: }] }`; `update` thay toàn bộ items (đồng bộ theo `type_id`, không xoá WP).

- [ ] **Step 1: Test (fail)** — các case: create hợp lệ; create thiếu default → lỗi; clone đặt tên `"X - Custom"`, giữ items, không gán project, `is_default` false; destroy khi còn project → fail và liệt kê tên project; assign vào scheme inactive → fail; update gỡ Type không làm đổi `WorkPackage` nào (`expect { }.not_to change(WorkPackage, :count)` và type_id không đổi); `impact` đếm đúng số project và số WP của Type bị gỡ trong các project đó.

- [ ] **Step 2: Implement**

```ruby
module TypeSchemes
  class SchemeService
    class << self
      def create(params) = save(TypeScheme.new, params)
      def update(scheme, params) = save(scheme, params)

      def clone(scheme)
        copy = TypeScheme.new(name: "#{scheme.name} - Custom", description: scheme.description, active: scheme.active)
        scheme.items.each { |i| copy.items.build(type_id: i.type_id, position: i.position, is_default: i.is_default) }
        copy.save ? ok(copy) : fail_with(copy)
      end

      def deactivate(scheme)
        scheme.update(active: false) ? ok(scheme) : fail_with(scheme)
      end

      def destroy(scheme)
        scheme.destroy ? ok(scheme) : fail_with(scheme)
      end

      def assign(project, scheme)
        record = ProjectTypeScheme.find_or_initialize_by(project_id: project.id)
        record.scheme = scheme
        record.save ? ok(record) : fail_with(record)
      end

      def unassign(project)
        ProjectTypeScheme.where(project_id: project.id).destroy_all
        ServiceResult.success
      end

      def impact(scheme, removed_type_ids: [])
        project_ids = scheme.project_assignments.pluck(:project_id)
        counts = WorkPackage.where(project_id: project_ids, type_id: removed_type_ids).group(:type_id).count
        { project_count: project_ids.size, work_package_counts: counts }
      end

      private

      def save(scheme, params)
        TypeScheme.transaction do
          scheme.assign_attributes(params.slice(:name, :description))
          sync_items(scheme, params[:items]) if params.key?(:items)
          scheme.save ? ok(scheme) : fail_with(scheme)
        end
      end

      def sync_items(scheme, items)
        wanted = items.index_by { |i| i[:type_id].to_i }
        scheme.items.each { |i| i.mark_for_destruction unless wanted.key?(i.type_id) }
        wanted.each do |type_id, attrs|
          item = scheme.items.find { |i| i.type_id == type_id } || scheme.items.build(type_id:)
          item.assign_attributes(position: attrs[:position], is_default: attrs[:is_default] || false)
        end
      end

      def ok(result) = ServiceResult.success(result:)
      def fail_with(model) = ServiceResult.failure(result: model, errors: model.errors)
    end
  end
end
```

Lưu ý: unique index `idx_type_scheme_item_one_default` có thể va chạm khi đổi default trong cùng transaction; nếu xảy ra, sync_items phải bỏ cờ default của tất cả item trước (`scheme.items.each { _1.is_default = false }`) rồi mới gán — thêm dòng đó đầu `sync_items` nếu test lộ ra.

- [ ] **Step 3: Run & commit** — `bundle exec rspec modules/type_schemes/spec/services` → PASS.

```bash
git add modules/type_schemes && git commit -m "feat(type-schemes): scheme service"
```

---

### Task 5: Permission, Admin UI

**Files:**
- Modify: `engine.rb` (`menu :admin_menu`, `project_module`/`permission`)
- Create: `app/controllers/admin/type_schemes_controller.rb`, views/components `index`, `form`, routes trong `config/routes.rb` của module, i18n
- Test: `spec/features/admin/type_schemes_spec.rb`, `spec/permissions/assign_type_scheme_spec.rb`

**Interfaces:**
- Consumes: `SchemeService`.
- Produces: route `admin_type_schemes_path` (+ `new/edit/clone/deactivate`), permission `:assign_type_scheme`.

- [ ] **Step 1:** Mở `app/controllers/admin/settings/project_phase_definitions_controller.rb` và `app/components/settings/project_phase_definitions/*` làm mẫu cấu trúc (index, new/create, edit/update, destroy, turbo stream, drag-reorder). Tạo controller tương ứng, `before_action :require_admin`, chỉ gọi `SchemeService`. Index hiển thị Name / số Project (`project_assignments.count`) / Status, actions Create / Edit / Clone / Deactivate / Delete. Delete lỗi ⇒ flash liệt kê project.
- [ ] **Step 2:** Form: Name, Description, danh sách Type (tất cả `Type.order(:position)` với checkbox), kéo-thả sắp xếp, radio Default. Khi submit gỡ Type: controller tính `SchemeService.impact` và nếu `project_count > 0` hiển thị trang xác nhận với 2 cảnh báo: "Scheme dùng bởi N project" và "Type X đang dùng bởi M work package. Work package hiện có không đổi." (US-05, §13, §14). Chỉ lưu khi `confirm=1`.
- [ ] **Step 3:** Engine:

```ruby
register "openproject-type_schemes", author_url: "https://www.openproject.org", bundled: true do
  menu :admin_menu, :type_schemes, { controller: "/admin/type_schemes", action: :index },
       if: proc { User.current.admin? }, caption: :"type_schemes.plural", parent: :admin_work_packages
  project_module :type_schemes, dependencies: :work_package_tracking do
    permission :assign_type_scheme,
               { "projects/settings/type_scheme": %i[show update] },
               permissible_on: :project, require: :member
  end
end
```

(Kiểm tra tên `parent:` hợp lệ trong `config/initializers/menus.rb` quanh nhóm Work packages của Administration; nếu không có, đặt vào nhóm gần nhất đang tồn tại.) Permission label: `permission_assign_type_scheme` + `project_module_type_schemes`.

- [ ] **Step 4:** Feature spec (js: false nếu được): admin tạo scheme 3 Type, chọn default, thấy trong danh sách; clone; delete bị chặn khi có project; gỡ Type hiện dialog xác nhận có số project/WP. Permission spec theo mẫu `spec/permissions/select_project_custom_fields_spec.rb`.
- [ ] **Step 5:** Run `bundle exec rspec modules/type_schemes/spec/features modules/type_schemes/spec/permissions` rồi commit `feat(type-schemes): admin UI and permission`.

---

### Task 6: Project Settings UI

**Files:**
- Create: `app/controllers/projects/settings/type_scheme_controller.rb`, view `show`, route `resource :type_scheme` trong project settings scope, menu item
- Test: `spec/features/projects/settings/type_scheme_spec.rb`

**Interfaces:** Consumes `SchemeService.assign/unassign`, `Resolver.allowed_types`.

- [ ] **Step 1:** Mẫu: `app/controllers/projects/settings/subitems_controller.rb` + `config/initializers/menus.rb:820-850` (cách đăng ký `project_menu_items`; trong module dùng `menu :project_menu, :settings_type_scheme, ..., if: ->(p) { User.current.allowed_in_project?(:assign_type_scheme, p) }, parent: :settings`).
- [ ] **Step 2:** `show`: select Scheme (active), hiển thị "Available Types" = `Resolver.allowed_types(@project)` kèm default; nếu giao scheme ∩ enabled_types rỗng hoặc thiếu Type, hiện cảnh báo "Type X thuộc scheme nhưng chưa bật trong project". `update`: `assign` hoặc `unassign` khi chọn rỗng.
- [ ] **Step 3:** Feature spec: user có permission đổi scheme và thấy danh sách; user không có permission nhận 403; sau khi gán, trang tạo WP (API schema) chỉ có Type của scheme.
- [ ] **Step 4:** Run + commit `feat(type-schemes): project settings assignment`.

---

### Task 7: API v3

**Files:**
- Create: `lib/api/v3/type_schemes/{type_schemes_api,type_scheme_representer,type_scheme_collection_representer,project_type_scheme_api}.rb`; `add_api_endpoint "API::V3::Root"` và `add_api_path` trong engine
- Create: `docs/api/apiv3/paths/type_scheme*.yml`, `components/schemas/type_scheme*.yml` (theo `docs/api/apiv3/*project_phase_definition*.yml`)
- Test: `spec/requests/api/v3/type_schemes/*_spec.rb`

**Interfaces:** Endpoints theo spec §7; `GET available_types` trả cùng thứ tự với `Resolver.allowed_types` + cờ `default`.

- [ ] **Step 1:** Mẫu: `lib/api/v3/project_phase_definitions/*` và `Utilities::Endpoints::Index/Show`; engine mount như `modules/job_status` (`add_api_endpoint "API::V3::Root" { mount ::API::V3::TypeSchemes::TypeSchemesAPI }`; project-scoped mount qua `add_api_endpoint "API::V3::Projects::ProjectsAPI", :id`).
- [ ] **Step 2:** Test từng endpoint: list/show cho user thường (200), create/patch/delete cho admin (201/200/204) và 403 cho user thường, `PUT projects/:id/type_scheme` yêu cầu `assign_type_scheme` (403 nếu thiếu), delete scheme còn project ⇒ 422 với tên project, body create theo idea (§18) hợp lệ, `available_types` đúng thứ tự và default.
- [ ] **Step 3:** Implement bằng `SchemeService`, không logic trùng lặp trong API.
- [ ] **Step 4:** Run `bundle exec rspec modules/type_schemes/spec/requests` + commit `feat(type-schemes): API v3`.

---

### Task 8: Default Scheme cho project mới và migration dữ liệu

**Files:**
- Create: `lib/open_project/type_schemes/project_created_listener.rb`, `lib/tasks/type_schemes.rake`
- Modify: `engine.rb` (subscribe `OpenProject::Events::PROJECT_CREATED` trong `config.to_prepare`), `app/views` admin: toggle "Default scheme cho project mới"
- Test: `spec/lib/project_created_listener_spec.rb`, `spec/tasks/type_schemes_rake_spec.rb`

**Interfaces:** `rake type_schemes:migrate[mode]` với `mode ∈ dry_run|auto|manual`.

- [ ] **Step 1:** Test listener: có scheme `is_default` + project mới ⇒ có `ProjectTypeScheme`; không có scheme default hoặc project đã có assignment ⇒ không tạo. Xem payload PROJECT_CREATED ở `app/services/projects/create_service.rb`/`lib/open_project/events.rb` và mẫu subscribe ở `modules/webhooks/lib/open_project/webhooks/event_resources/project.rb`.
- [ ] **Step 2:** Implement listener (`SchemeService.assign(project, default_scheme)` nếu có).
- [ ] **Step 3:** Rake task: tạo "Default Scheme" gồm các Type đang được bật ở ít nhất một project (`Type.joins(:projects)`), Type mặc định = Type có `is_default` native hoặc Type đầu tiên theo position; `dry_run` chỉ in kế hoạch (project nào → scheme nào, số WP bị ảnh hưởng = 0 vì scheme chỉ lọc tạo mới), `auto` thực thi, `manual` chỉ tạo scheme không gán project. Khuyến nghị trong docs: dry_run → review → auto. Test bằng cách chạy task qua `Rake::Task` với dữ liệu mẫu và kiểm tra số `ProjectTypeScheme`.
- [ ] **Step 4:** Test tính an toàn gỡ module: `spec/migrations`-style kiểm tra rollback `db:rollback` xoá 3 bảng và `Type.count`, `WorkPackage.count` không đổi.
- [ ] **Step 5:** Commit `feat(type-schemes): default scheme and data migration task`.

---

### Task 9: E2E, regression, tài liệu

**Files:**
- Create: `spec/features/work_packages/create_with_scheme_spec.rb` (js: true), `docs/system-admin-guide/.../type-schemes/README.md` (chọn thư mục đúng theo `docs/system-admin-guide/` hiện có), cập nhật spec §10 với kết quả spike
- Test: toàn bộ module + regression core

- [ ] **Step 1:** E2E: admin tạo scheme [Epic, Story*, Task]; gán cho project; user mở màn hình tạo WP ⇒ chỉ thấy 3 Type, Type mặc định là Story (nếu spike xác nhận); POST API tạo WP Type Bug ⇒ 422; WP Bug có sẵn vẫn mở và sửa subject được; gỡ Task khỏi scheme ⇒ WP Task cũ không đổi.
- [ ] **Step 2:** Regression: `bundle exec rspec spec/contracts/work_packages spec/services/work_packages spec/requests/api/v3/work_packages/form_resource_spec.rb spec/features/work_packages/create` (đường dẫn cuối có thể khác; dùng `rg -l "WorkPackages::CreateService|work_packages/form" spec` để chọn bộ gần nhất) ⇒ PASS.
- [ ] **Step 3:** Lint: `bundle exec rubocop modules/type_schemes` và `bundle exec erb_lint` nếu có; i18n: `bundle exec rspec spec/i18n_spec.rb`.
- [ ] **Step 4:** Viết docs người dùng (admin tạo scheme, gán, ý nghĩa "chỉ áp dụng cho tạo mới", migration dry-run, gỡ module).
- [ ] **Step 5:** Commit `docs(type-schemes): admin guide and e2e coverage`.

---

## Self-Review

- **Spec coverage:** US-01..05 → Task 1,4,5; gán project/available types → Task 2,6,7; lọc khi tạo + WP cũ giữ nguyên → Task 3,9; clone/delete guard/cảnh báo → Task 4,5; permission → Task 5,6,7; API → Task 7; Default Scheme + migration DRY RUN/AUTO/MANUAL → Task 8; compatibility khi gỡ module → Task 8 Step 4; core modification = 0 file → Global Constraints + Task 3.
- **Placeholder scan:** các điểm "xác minh khi thực thi" (menu parent, đường dẫn regression, payload PROJECT_CREATED, caller của `assignable_types` cần Relation) đều kèm hướng kiểm tra cụ thể, không để trống hành vi.
- **Consistency:** `Resolver.for_project` / `.allowed_types`, `SchemeService.{create,update,clone,deactivate,destroy,assign,unassign,impact}`, `ProjectTypeScheme`, lỗi `:not_in_scheme` dùng thống nhất giữa các task.
