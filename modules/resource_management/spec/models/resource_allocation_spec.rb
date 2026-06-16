# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ResourceAllocation do
  describe "associations" do
    subject { described_class.new(principal_explicit: false) }

    it { is_expected.to belong_to(:entity).required }
    it { is_expected.to belong_to(:requested_by).class_name("User").optional }
    it { is_expected.to belong_to(:reviewed_by).class_name("User").optional }

    # The association is optional; principal is only required (via a conditional
    # validation) for explicit allocations, so the matcher is checked against a
    # filter-based one where principal may legitimately be nil.
    it "has an optional principal" do
      allocation = build(:resource_allocation, principal_explicit: false, principal: nil, filter_name: "Devs")
      expect(allocation).to belong_to(:principal).class_name("User").inverse_of(:resource_allocations).optional
    end
  end

  describe "state enum" do
    it "exposes the four allowed string-backed states" do
      expect(described_class.states).to eq(
        "requested" => "requested",
        "allocated" => "allocated",
        "rejected" => "rejected",
        "canceled" => "canceled"
      )
    end

    it "rejects unknown state values" do
      expect { described_class.new(state: "unknown") }.to raise_error(ArgumentError)
    end

    it "exposes a factory trait per state value" do
      described_class.states.each_key do |value|
        expect(build(:resource_allocation, value.to_sym).state).to eq(value)
      end
    end
  end

  describe "#allocated_hours" do
    subject(:allocation) { described_class.new }

    describe "reader" do
      it "returns the persisted minutes as hours" do
        allocation.allocated_time = 150
        expect(allocation.allocated_hours).to eq(2.5)
      end

      it "is nil when allocated_time is unset" do
        expect(allocation.allocated_hours).to be_nil
      end
    end

    describe "writer" do
      it "stores a numeric value of hours as minutes" do
        allocation.allocated_hours = 8
        expect(allocation.allocated_time).to eq(480)
      end

      it "parses a duration string via chronic duration" do
        allocation.allocated_hours = "2h30m"
        expect(allocation.allocated_time).to eq(150)
      end

      it "parses a decimal-hours string" do
        allocation.allocated_hours = "2.5"
        expect(allocation.allocated_time).to eq(150)
      end

      it "clears the value when given nil" do
        allocation.allocated_time = 480
        allocation.allocated_hours = nil
        expect(allocation.allocated_time).to be_nil
      end

      it "falls back to nil for an unparseable string (so validation can reject it)" do
        allocation.allocated_hours = "not a duration"
        expect(allocation.allocated_time).to be_nil
      end
    end
  end

  describe "#user_assigned? / #filter_based? / #needs_principal_assignment?" do
    let(:assignee) { build_stubbed(:user) }

    context "with an explicit user allocation" do
      subject(:allocation) { described_class.new(principal_explicit: true, principal: assignee) }

      it { is_expected.to be_user_assigned }
      it { is_expected.not_to be_filter_based }
      it { is_expected.not_to be_needs_principal_assignment }
    end

    context "with an unassigned filter placeholder" do
      subject(:allocation) { described_class.new(principal_explicit: false, principal: nil) }

      it { is_expected.not_to be_user_assigned }
      it { is_expected.to be_filter_based }
      it { is_expected.to be_needs_principal_assignment }
    end

    context "with a filter placeholder that has a principal assigned" do
      subject(:allocation) { described_class.new(principal_explicit: false, principal: assignee) }

      it { is_expected.to be_user_assigned }
      it { is_expected.to be_filter_based }
      it { is_expected.not_to be_needs_principal_assignment }
    end
  end

  describe "#schedule_violation, #entity_start_date, #entity_due_date" do
    let(:work_package) { build_stubbed(:work_package, start_date: Date.new(2026, 1, 10), due_date: Date.new(2026, 1, 20)) }

    def allocation_for(start_date:, end_date:, entity: work_package)
      described_class.new(entity:, start_date:, end_date:)
    end

    it "exposes the entity's start and due dates" do
      allocation = allocation_for(start_date: Date.new(2026, 1, 12), end_date: Date.new(2026, 1, 15))

      expect(allocation.entity_start_date).to eq(Date.new(2026, 1, 10))
      expect(allocation.entity_due_date).to eq(Date.new(2026, 1, 20))
    end

    context "when the allocation is fully within the entity's schedule" do
      it "returns nil" do
        expect(allocation_for(start_date: Date.new(2026, 1, 12), end_date: Date.new(2026, 1, 15)).schedule_violation)
          .to be_nil
      end
    end

    context "when the allocation exactly matches the entity's bounds" do
      it "returns nil (bounds are inclusive)" do
        expect(allocation_for(start_date: Date.new(2026, 1, 10), end_date: Date.new(2026, 1, 20)).schedule_violation)
          .to be_nil
      end
    end

    context "when the allocation starts before the entity's start date" do
      it "returns :before_start" do
        expect(allocation_for(start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 15)).schedule_violation)
          .to eq(:before_start)
      end
    end

    context "when the allocation ends after the entity's due date" do
      it "returns :after_finish" do
        expect(allocation_for(start_date: Date.new(2026, 1, 12), end_date: Date.new(2026, 1, 25)).schedule_violation)
          .to eq(:after_finish)
      end
    end

    context "when the allocation spills out on both ends" do
      it "returns :before_and_after" do
        expect(allocation_for(start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 25)).schedule_violation)
          .to eq(:before_and_after)
      end
    end

    context "when the entity has no start date" do
      let(:work_package) { build_stubbed(:work_package, start_date: nil, due_date: Date.new(2026, 1, 20)) }

      it "ignores the missing start bound and only flags the due date" do
        expect(allocation_for(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 15)).schedule_violation)
          .to be_nil
        expect(allocation_for(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 25)).schedule_violation)
          .to eq(:after_finish)
      end
    end

    context "when the entity has no due date" do
      let(:work_package) { build_stubbed(:work_package, start_date: Date.new(2026, 1, 10), due_date: nil) }

      it "ignores the missing due bound and only flags the start date" do
        expect(allocation_for(start_date: Date.new(2026, 1, 12), end_date: Date.new(2026, 1, 25)).schedule_violation)
          .to be_nil
        expect(allocation_for(start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 25)).schedule_violation)
          .to eq(:before_start)
      end
    end

    context "when the entity has neither date" do
      let(:work_package) { build_stubbed(:work_package, start_date: nil, due_date: nil) }

      it "returns nil (nothing to compare against)" do
        expect(allocation_for(start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 25)).schedule_violation)
          .to be_nil
      end
    end

    context "when the allocation dates are blank" do
      it "returns nil" do
        expect(allocation_for(start_date: nil, end_date: nil).schedule_violation).to be_nil
      end
    end

    context "without an entity" do
      it "returns nil" do
        allocation = described_class.new(start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 25))

        expect(allocation.entity_start_date).to be_nil
        expect(allocation.schedule_violation).to be_nil
      end
    end
  end

  describe ".needs_principal_assignment" do
    shared_let(:project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }

    let!(:unassigned_placeholder) do
      create(:resource_allocation, entity: work_package, principal_explicit: false, principal: nil, filter_name: "Devs")
    end

    before do
      # An explicit allocation and an already-assigned placeholder must be excluded.
      create(:resource_allocation, entity: work_package)
      create(:resource_allocation, entity: work_package,
                                   principal_explicit: false, principal: create(:user), filter_name: "Devs")
    end

    it "returns only filter placeholders without a principal" do
      expect(described_class.needs_principal_assignment).to contain_exactly(unassigned_placeholder)
    end
  end

  describe ".for_principal" do
    shared_let(:project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }
    shared_let(:user) { create(:user) }

    let!(:for_user) { create(:resource_allocation, entity: work_package, principal: user) }

    before { create(:resource_allocation, entity: work_package, principal: create(:user)) }

    it "returns only the allocations of the given principal" do
      expect(described_class.for_principal(user)).to contain_exactly(for_user)
    end
  end

  describe ".for_project" do
    shared_let(:project) { create(:project) }
    shared_let(:other_project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }
    shared_let(:other_work_package) { create(:work_package, project: other_project) }

    let!(:in_project) { create(:resource_allocation, entity: work_package) }

    before { create(:resource_allocation, entity: other_work_package) }

    it "returns only allocations whose entity belongs to the given project" do
      expect(described_class.for_project(project)).to contain_exactly(in_project)
    end

    it "accepts a project id as well as a record" do
      expect(described_class.for_project(project.id)).to contain_exactly(in_project)
    end
  end

  describe "entity GlobalID handling" do
    shared_let(:project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }

    subject(:allocation) { described_class.new }

    describe "#entity_gid" do
      it "returns the GlobalID string of the entity" do
        allocation.entity = work_package
        expect(allocation.entity_gid).to eq(work_package.to_gid.to_s)
      end

      it "is an empty string when no entity is set" do
        expect(allocation.entity_gid).to eq("")
      end
    end

    describe "#entity=" do
      it "assigns a plain record directly" do
        allocation.entity = work_package
        expect(allocation.entity).to eq(work_package)
      end

      it "resolves a GlobalID string to the record" do
        allocation.entity = work_package.to_gid.to_s
        expect(allocation.entity).to eq(work_package)
      end

      it "round-trips an entity through entity_gid" do
        allocation.entity = work_package.to_gid.to_s
        expect(allocation.entity_gid).to eq(work_package.to_gid.to_s)
      end

      it "ignores a GlobalID of a type outside ALLOWED_ENTITY_TYPES" do
        disallowed = create(:user)
        allocation.entity = disallowed.to_gid.to_s
        expect(allocation.entity).to be_nil
      end
    end
  end

  describe "validations" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
    shared_let(:work_package) { create(:work_package, project:) }

    let(:allocation) { build(:resource_allocation, entity: work_package, principal: owner) }

    it "is valid with the factory defaults" do
      expect(allocation).to be_valid
    end

    describe "presence" do
      it "requires entity" do
        allocation.entity = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:entity]).to be_present
      end

      it "requires state" do
        allocation.state = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:state]).to be_present
      end

      it "requires start_date" do
        allocation.start_date = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:start_date]).to be_present
      end

      it "requires end_date" do
        allocation.end_date = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:end_date]).to be_present
      end

      it "requires allocated_time" do
        allocation.allocated_time = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:allocated_time]).to be_present
      end

      it "requires a principal for an explicit allocation" do
        allocation.principal_explicit = true
        allocation.principal = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors.symbols_for(:principal)).to include(:blank)
      end

      it "does not require a principal for a filter placeholder" do
        allocation.principal_explicit = false
        allocation.principal = nil
        allocation.filter_name = "Devs"
        expect(allocation).to be_valid
      end
    end

    describe "entity type" do
      it "lists the supported entity types" do
        expect(described_class::ALLOWED_ENTITY_TYPES).to eq(%w[WorkPackage])
      end

      it "is valid when the entity type is in the allowed list" do
        allocation.entity = work_package
        expect(allocation).to be_valid
      end

      it "is invalid when the entity type is outside the allowed list" do
        allocation.entity = create(:resource_planner, project:, principal: owner)
        expect(allocation).not_to be_valid
        expect(allocation.errors.symbols_for(:entity_type)).to include(:inclusion)
      end
    end

    describe "allocated_time numericality" do
      it "is invalid when zero" do
        allocation.allocated_time = 0
        expect(allocation).not_to be_valid
        expect(allocation.errors.symbols_for(:allocated_time)).to include(:greater_than)
      end

      it "is invalid when negative" do
        allocation.allocated_time = -1
        expect(allocation).not_to be_valid
        expect(allocation.errors.symbols_for(:allocated_time)).to include(:greater_than)
      end

      it "is valid when positive" do
        allocation.allocated_time = 1
        expect(allocation).to be_valid
      end

      it "is valid at the upper cap" do
        allocation.allocated_time = described_class::MAX_ALLOCATED_TIME
        expect(allocation).to be_valid
      end

      it "is invalid (rather than overflowing the column) above the cap" do
        allocation.allocated_time = described_class::MAX_ALLOCATED_TIME + 1
        expect(allocation).not_to be_valid
        expect(allocation.errors.symbols_for(:allocated_time)).to include(:less_than_or_equal_to)
      end
    end

    describe "date range" do
      context "when end_date is after start_date" do
        before do
          allocation.start_date = Date.new(2026, 1, 1)
          allocation.end_date = Date.new(2026, 1, 2)
        end

        it "is valid" do
          expect(allocation).to be_valid
        end
      end

      context "when end_date equals start_date" do
        before do
          allocation.start_date = Date.new(2026, 1, 1)
          allocation.end_date = Date.new(2026, 1, 1)
        end

        it "is valid (single-day allocation)" do
          expect(allocation).to be_valid
        end
      end

      context "when end_date is before start_date" do
        before do
          allocation.start_date = Date.new(2026, 1, 5)
          allocation.end_date = Date.new(2026, 1, 2)
        end

        it "is invalid" do
          expect(allocation).not_to be_valid
          expect(allocation.errors.symbols_for(:end_date)).to include(:greater_than_start_date)
        end
      end
    end

    describe "allocation kind (principal_explicit)" do
      let(:filter) do
        UserQuery.new.filter_for(:name).tap do |f|
          f.operator = "~"
          f.values = ["alice"]
        end
      end

      context "when explicit (principal_explicit: true)" do
        before { allocation.principal_explicit = true }

        it "is valid with a principal and no filter" do
          expect(allocation).to be_valid
        end

        it "rejects a filter_name" do
          allocation.filter_name = "Devs"
          expect(allocation).not_to be_valid
          expect(allocation.errors.symbols_for(:filter_name)).to include(:present)
        end

        it "rejects a user_filter" do
          allocation.user_filter = [filter]
          expect(allocation).not_to be_valid
          expect(allocation.errors.symbols_for(:user_filter)).to include(:present)
        end
      end

      context "when filter-based (principal_explicit: false)" do
        before do
          allocation.principal_explicit = false
          allocation.principal = nil
        end

        it "requires a filter_name" do
          allocation.filter_name = nil
          expect(allocation).not_to be_valid
          expect(allocation.errors.symbols_for(:filter_name)).to include(:blank)
        end

        it "is valid as an unassigned placeholder with a name" do
          allocation.filter_name = "Full stack Developer (DE-EN)"
          expect(allocation).to be_valid
        end

        it "allows a real principal alongside a named filter (assigned placeholder)" do
          allocation.principal = owner
          allocation.filter_name = "Full stack Developer (DE-EN)"
          allocation.user_filter = [filter]
          expect(allocation).to be_valid
        end
      end
    end
  end

  describe "user_filter serialization" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
    shared_let(:work_package) { create(:work_package, project:) }

    it "serializes filters using the same coder as UserQuery" do
      coder = described_class.type_for_attribute(:user_filter).coder
      user_query_coder = UserQuery.type_for_attribute(:filters).coder

      expect(coder).to be_a(Queries::Serialization::Filters)
      expect(coder.klass).to eq(UserQuery)
      expect(coder.registered_filters).to eq(user_query_coder.registered_filters)
    end

    it "round-trips a UserQuery filter through the database" do
      filter = UserQuery.new.filter_for(:name)
      filter.operator = "~"
      filter.values = ["alice"]

      allocation = create(:resource_allocation,
                          entity: work_package,
                          principal_explicit: false,
                          principal: nil,
                          filter_name: "Alices",
                          user_filter: [filter])

      reloaded = described_class.find(allocation.id)
      expect(reloaded.user_filter.size).to eq(1)
      expect(reloaded.user_filter.first).to be_a(Queries::Users::Filters::NameFilter)
      expect(reloaded.user_filter.first.operator).to eq("~")
      expect(reloaded.user_filter.first.values).to eq(["alice"])
    end

    it "defaults to an empty array" do
      allocation = create(:resource_allocation, entity: work_package, principal: owner)
      expect(allocation.reload.user_filter).to eq([])
    end

    it "round-trips the custom-field filters from the :with_user_filter trait" do
      allocation = create(:resource_allocation, :with_user_filter, entity: work_package)

      filters = allocation.reload.user_filter
      expect(filters.size).to eq(2)

      job_title = UserCustomField.find_by(name: "Job title")
      language = UserCustomField.find_by(name: "Spoken language")

      job_title_filter = filters.find { |f| f.name.to_s == job_title.column_name }
      language_filter = filters.find { |f| f.name.to_s == language.column_name }

      expect(job_title_filter.operator).to eq("=")
      expect(job_title_filter.values).to eq(job_title.custom_options.where(value: "Developer").pluck(:id).map(&:to_s))

      # "is (OR)" — matches users speaking German or English.
      expect(language_filter.operator).to eq("=")
      expect(language_filter.values)
        .to match_array(language.custom_options.where(value: %w[German English]).pluck(:id).map(&:to_s))
    end
  end

  describe "matching users with the :with_user_filter criteria" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:work_package) { create(:work_package, project:) }

    # Materializes the "Job title" and "Spoken language" custom fields and the
    # Developer + (German OR English) filter.
    shared_let(:allocation) { create(:resource_allocation, :with_user_filter, entity: work_package) }
    shared_let(:job_title) { UserCustomField.find_by(name: "Job title") }
    shared_let(:language) { UserCustomField.find_by(name: "Spoken language") }

    def option_id(custom_field, value)
      custom_field.custom_options.find_by(value:).id
    end

    def user_with(job_title_value, *languages)
      create(:user).tap do |user|
        user.custom_field_values = {
          job_title.id => option_id(job_title, job_title_value),
          language.id => languages.map { |spoken| option_id(language, spoken) }
        }
        user.save!(validate: false)
      end
    end

    shared_let(:german_developer) { user_with("Developer", "German") }
    shared_let(:english_developer) { user_with("Developer", "English") }
    shared_let(:bilingual_developer) { user_with("Developer", "French", "English") }
    shared_let(:french_developer) { user_with("Developer", "French") }
    shared_let(:german_designer) { user_with("Designer", "German") }

    describe "#candidate_query" do
      # `UserQuery#results` is scoped to what the current user may see.
      current_user { create(:admin) }

      it "is a UserQuery carrying the stored filter criteria" do
        query = allocation.candidate_query

        expect(query).to be_a(UserQuery)
        expect(query.filters.map { |f| f.name.to_s })
          .to contain_exactly(job_title.column_name, language.column_name)
      end

      it "resolves to developers speaking German or English (is (OR)), and excludes the rest" do
        results = allocation.candidate_query.results

        expect(results).to include(german_developer, english_developer, bilingual_developer)
        expect(results).not_to include(french_developer, german_designer)
      end
    end
  end

  describe ".allocated_for_work_packages" do
    shared_let(:work_package) { create(:work_package) }
    shared_let(:other_work_package) { create(:work_package) }

    def allocations_for(*work_packages)
      described_class.allocated_for_work_packages(work_packages)
    end

    it "groups the work package's allocations by entity id" do
      first = create(:resource_allocation, entity: work_package, allocated_time: 120)
      second = create(:resource_allocation, entity: work_package, allocated_time: 300)

      expect(allocations_for(work_package)).to eq(work_package.id => [first, second])
    end

    it "includes only allocations in the 'allocated' state" do
      allocated = create(:resource_allocation, entity: work_package, allocated_time: 120)
      create(:resource_allocation, :requested, entity: work_package, allocated_time: 999)
      create(:resource_allocation, :rejected, entity: work_package, allocated_time: 999)
      create(:resource_allocation, :canceled, entity: work_package, allocated_time: 999)

      expect(allocations_for(work_package)).to eq(work_package.id => [allocated])
    end

    it "covers several work packages and omits those without allocations" do
      mine = create(:resource_allocation, entity: work_package, allocated_time: 120)
      create(:resource_allocation, entity: other_work_package, allocated_time: 500)

      result = allocations_for(work_package, other_work_package)

      expect(result[work_package.id]).to eq([mine])
      expect(result).to have_key(other_work_package.id)
    end

    it "is empty when the work packages have no allocations" do
      expect(allocations_for(work_package)).to eq({})
    end
  end

  describe ".overbooked_ids" do
    shared_let(:work_package) { create(:work_package) }
    shared_let(:assignee) { create(:user) }

    # The factory books Mon-Fri 2026-01-05..09 with 40 hours — exactly the
    # capacity of a full-time (8h/day) week.
    def allocation(**attributes)
      create(:resource_allocation, entity: work_package, principal: assignee, **attributes)
    end

    def overbooked_allocation
      allocation(start_date: Date.new(2026, 2, 2), end_date: Date.new(2026, 2, 2), allocated_time: 16 * 60)
    end

    context "when the assigned user has working hours configured" do
      shared_let(:working_hours) { create(:user_working_hours, user: assignee, valid_from: Date.new(2025, 1, 1)) }

      it "returns the ids of the allocations in overbooked ranges" do
        fitting = allocation
        overbooked = overbooked_allocation

        expect(described_class.overbooked_ids([fitting, overbooked])).to eq(Set[overbooked.id])
      end

      it "is empty when every allocation fits" do
        fitting = allocation

        expect(described_class.overbooked_ids([fitting])).to be_empty
      end
    end

    context "when the assigned user has no working hours configured" do
      it "is empty, since the user's capacity is unknown rather than zero" do
        expect(described_class.overbooked_ids([overbooked_allocation])).to be_empty
      end
    end

    it "ignores filter-based allocations without an assigned user" do
      filter = create(:resource_allocation,
                      entity: work_package, principal_explicit: false, principal: nil, filter_name: "Developer")

      expect(described_class.overbooked_ids([filter])).to be_empty
    end
  end
end
