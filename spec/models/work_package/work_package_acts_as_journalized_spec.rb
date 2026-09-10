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

RSpec.describe WorkPackage do
  describe "#journals (and the saving of them)" do
    shared_let(:user) { create(:user) }
    shared_let(:type) { create(:type) }
    shared_let(:other_type) { create(:type) }
    shared_let(:status) { create(:default_status) }
    shared_let(:priority) { create(:priority) }
    shared_let(:project) { create(:project, types: [type, other_type]) }
    shared_let(:parent_work_package) { create(:work_package) }
    shared_let(:other_status) { create(:status) }
    shared_let(:other_priority) { create(:priority) }
    shared_let(:other_user) { create(:user) }
    shared_let(:other_project) { create(:project) }
    shared_let(:category) { create(:category) }
    shared_let(:version) { create(:version) }
    shared_let(:other_version) { create(:version) }
    shared_let(:project_phase_definition) { create(:project_phase_definition) }
    shared_let(:other_work_package) { build_stubbed(:work_package) }
    shared_let(:other_user) { create(:user) }

    current_user { user }

    context "on creation" do
      let(:journable) do
        described_class.new(author: user)
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Initial subject",
                         "description" => "Initial description",
                         "type_id" => :type,
                         "status_id" => :status,
                         "priority_id" => :priority,
                         "project_id" => :project,
                         "category_id" => :category,
                         "target_version_ids_replacements" => -> { [version.id] },
                         "start_date" => Date.new(2013, 1, 24),
                         "due_date" => Date.new(2013, 1, 31),
                         "done_ratio" => 100,
                         "estimated_hours" => 40.0,
                         "derived_estimated_hours" => 50.0,
                         "remaining_hours" => 3.0,
                         "story_points" => 10,
                         "duration" => 8,
                         "schedule_manually" => false,
                         "ignore_non_working_days" => false,
                         "assigned_to_id" => :other_user,
                         "responsible_id" => :other_user,
                         "parent_id" => :parent_work_package,
                         "project_phase_definition_id" => :project_phase_definition
                       },
                       expected_values: {
                         "subject" => [nil, "Initial subject"],
                         "description" => [nil, "Initial description"],
                         "type_id" => [nil, :type],
                         "status_id" => [nil, :status],
                         "priority_id" => [nil, :priority],
                         "project_id" => [nil, :project],
                         "category_id" => [nil, :category],
                         "target_versions" => [nil, -> { version.id.to_s }],
                         "start_date" => [nil, Date.new(2013, 1, 24)],
                         "due_date" => [nil, Date.new(2013, 1, 31)],
                         "done_ratio" => [nil, 100],
                         "estimated_hours" => [nil, 40.0],
                         "derived_estimated_hours" => [nil, 50.0],
                         "remaining_hours" => [nil, 3.0],
                         "story_points" => [nil, 10],
                         "duration" => [nil, 8],
                         "schedule_manually" => [nil, false],
                         "ignore_non_working_days" => [nil, false],
                         "assigned_to_id" => [nil, :other_user],
                         "responsible_id" => [nil, :other_user],
                         "parent_id" => [nil, :parent_work_package],
                         "project_phase_definition_id" => [nil, :project_phase_definition]
                       },
                       expect_new_journal: true,
                       expect_predecessor_changed: false do
        it "results in created_at and updated_at being the same on the work package" do
          journable.save!
          # Just to ensure that there actually is nothing hidden in the DB
          journable.reload

          expect(journable.created_at)
            .to eql journable.updated_at
        end
      end
    end

    context "when nothing is changed" do
      context "for a work package that has only been created (single journal)" do
        shared_let(:journable) do
          create(:work_package,
                 journals: {
                   Time.current => { user:, notes: "First comment" }
                 })
        end

        include_examples "no journaled value changes for",
                         new_values_set: {}
      end

      context "for a work package that has been updated already (multiple journals)" do
        shared_let(:journable) do
          create(:work_package,
                 journals: {
                   5.days.ago => { user: },
                   4.days.ago => { user:, notes: "First comment" }
                 })
        end

        include_examples "no journaled value changes for",
                         new_values_set: {}
      end
    end

    context "on changes outside of aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               description: "Initial description",
               project:,
               type:,
               priority:,
               status:,
               start_date: Date.new(2026, 1, 9),
               due_date: nil,
               duration: 1,
               estimated_hours: 3.0,
               schedule_manually: true,
               assigned_to: user,
               responsible: user,
               category: nil,
               version:,
               ignore_non_working_days: true,
               journals: {
                 10.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject",
                         "description" => "Changed description",
                         "type_id" => :other_type,
                         "status_id" => :other_status,
                         "priority_id" => :other_priority,
                         "project_id" => :other_project,
                         "category_id" => :category,
                         "target_version_ids_replacements" => -> { [other_version.id] },
                         "start_date" => Date.new(2013, 1, 24),
                         "due_date" => Date.new(2013, 1, 31),
                         "done_ratio" => 100,
                         "estimated_hours" => 40.0,
                         "derived_estimated_hours" => 50.0,
                         "remaining_hours" => 3.0,
                         "story_points" => 10,
                         "duration" => 8,
                         "schedule_manually" => false,
                         "ignore_non_working_days" => false,
                         "assigned_to_id" => :other_user,
                         "responsible_id" => nil,
                         "parent_id" => :parent_work_package,
                         "project_phase_definition_id" => :project_phase_definition
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"],
                         "description" => ["Initial description", "Changed description"],
                         "type_id" => %i[type other_type],
                         "status_id" => %i[status other_status],
                         "priority_id" => %i[priority other_priority],
                         "project_id" => %i[project other_project],
                         "category_id" => [nil, :category],
                         "target_versions" => [-> { version.id.to_s }, -> { other_version.id.to_s }],
                         "start_date" => [Date.new(2026, 1, 9), Date.new(2013, 1, 24)],
                         "due_date" => [nil, Date.new(2013, 1, 31)],
                         "done_ratio" => [nil, 100],
                         "estimated_hours" => [3.0, 40.0],
                         "derived_estimated_hours" => [nil, 50.0],
                         "remaining_hours" => [nil, 3.0],
                         "story_points" => [nil, 10],
                         "duration" => [1, 8],
                         "schedule_manually" => [true, false],
                         "ignore_non_working_days" => [true, false],
                         "assigned_to_id" => %i[user other_user],
                         "responsible_id" => [:current_user, nil],
                         "parent_id" => [nil, :parent_work_package],
                         "project_phase_definition_id" => [nil, :project_phase_definition]
                       },
                       expect_new_journal: true
    end

    context "on changes within aggregation time for a work package with no update yet (single journal)" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               description: "Initial description",
               project:,
               type:,
               priority:,
               status:,
               start_date: Date.new(2026, 1, 9),
               due_date: nil,
               duration: 1,
               estimated_hours: 3.0,
               schedule_manually: true,
               assigned_to: user,
               responsible: user,
               category: nil,
               version:,
               ignore_non_working_days: true,
               journals: {
                 4.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject",
                         "description" => "Changed description",
                         "type_id" => :other_type,
                         "status_id" => :other_status,
                         "priority_id" => :other_priority,
                         "project_id" => :other_project,
                         "category_id" => :category,
                         "target_version_ids_replacements" => -> { [other_version.id] },
                         "start_date" => Date.new(2013, 1, 24),
                         "due_date" => Date.new(2013, 1, 31),
                         "done_ratio" => 100,
                         "estimated_hours" => 40.0,
                         "derived_estimated_hours" => 50.0,
                         "remaining_hours" => 3.0,
                         "story_points" => 10,
                         "duration" => 8,
                         "schedule_manually" => false,
                         "ignore_non_working_days" => false,
                         "assigned_to_id" => :other_user,
                         "responsible_id" => nil,
                         "parent_id" => :parent_work_package,
                         "project_phase_definition_id" => :project_phase_definition
                       },
                       expected_values: {
                         "subject" => [nil, "Changed subject"],
                         "description" => [nil, "Changed description"],
                         "type_id" => [nil, :other_type],
                         "status_id" => [nil, :other_status],
                         "priority_id" => [nil, :other_priority],
                         "project_id" => [nil, :other_project],
                         "category_id" => [nil, :category],
                         "target_versions" => [nil, -> { other_version.id.to_s }],
                         "start_date" => [nil, Date.new(2013, 1, 24)],
                         "due_date" => [nil, Date.new(2013, 1, 31)],
                         "done_ratio" => [nil, 100],
                         "estimated_hours" => [nil, 40.0],
                         "derived_estimated_hours" => [nil, 50.0],
                         "remaining_hours" => [nil, 3.0],
                         "story_points" => [nil, 10],
                         "duration" => [nil, 8],
                         "schedule_manually" => [nil, false],
                         "ignore_non_working_days" => [nil, false],
                         "assigned_to_id" => [nil, :other_user],
                         "responsible_id" => [nil, nil],
                         "parent_id" => [nil, :parent_work_package],
                         "project_phase_definition_id" => [nil, :project_phase_definition]
                       },
                       expect_new_journal: false
    end

    context "on changes within aggregation time for a work package with former updates (multiple journal)" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               description: "Initial description",
               project:,
               type:,
               priority:,
               status:,
               start_date: Date.new(2026, 1, 9),
               due_date: nil,
               duration: 1,
               estimated_hours: 3.0,
               schedule_manually: true,
               assigned_to: user,
               responsible: user,
               category: nil,
               version:,
               ignore_non_working_days: true,
               journals: {
                 # Both journals will be the exact same snapshot of the current state.
                 # For the sake of this test, this doesn't matter.
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject",
                         "description" => "Changed description",
                         "type_id" => :other_type,
                         "status_id" => :other_status,
                         "priority_id" => :other_priority,
                         "project_id" => :other_project,
                         "category_id" => :category,
                         "target_version_ids_replacements" => -> { [other_version.id] },
                         "start_date" => Date.new(2013, 1, 24),
                         "due_date" => Date.new(2013, 1, 31),
                         "done_ratio" => 100,
                         "estimated_hours" => 40.0,
                         "derived_estimated_hours" => 50.0,
                         "remaining_hours" => 3.0,
                         "story_points" => 10,
                         "duration" => 8,
                         "schedule_manually" => false,
                         "ignore_non_working_days" => false,
                         "assigned_to_id" => :other_user,
                         "responsible_id" => nil,
                         "parent_id" => :parent_work_package,
                         "project_phase_definition_id" => :project_phase_definition
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"],
                         "description" => ["Initial description", "Changed description"],
                         "type_id" => %i[type other_type],
                         "status_id" => %i[status other_status],
                         "priority_id" => %i[priority other_priority],
                         "project_id" => %i[project other_project],
                         "category_id" => [nil, :category],
                         "target_versions" => [-> { version.id.to_s }, -> { other_version.id.to_s }],
                         "start_date" => [Date.new(2026, 1, 9), Date.new(2013, 1, 24)],
                         "due_date" => [nil, Date.new(2013, 1, 31)],
                         "done_ratio" => [nil, 100],
                         "estimated_hours" => [3.0, 40.0],
                         "derived_estimated_hours" => [nil, 50.0],
                         "remaining_hours" => [nil, 3.0],
                         "story_points" => [nil, 10],
                         "duration" => [1, 8],
                         "schedule_manually" => [true, false],
                         "ignore_non_working_days" => [true, false],
                         "assigned_to_id" => %i[user other_user],
                         "responsible_id" => [:user, nil],
                         "parent_id" => [nil, :parent_work_package],
                         "project_phase_definition_id" => [nil, :project_phase_definition]
                       },
                       expect_new_journal: false
    end

    context "on changes within aggregation time for a different user" do
      shared_let(:journable) do
        create(:work_package,
               description: "Initial description",
               journals: {
                 4.minutes.ago => { user: other_user }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "description" => "Changed description"
                       },
                       expected_values: {
                         "description" => ["Initial description", "Changed description"]
                       },
                       expect_new_journal: true
    end

    context "on changes with aggregation disabled", with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               journals: {
                 # Both journals will be the exact same snapshot of the current state.
                 # For the sake of this test, this doesn't matter.
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject"
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"]
                       },
                       expect_new_journal: true
    end

    context "on attachment changes", with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:attachment) { build(:attachment) }
      let(:attachment_id) { "attachments_#{attachment.id}" }

      shared_let(:journable) do
        create(:work_package)
      end

      before do
        journable.attachments << attachment
        journable.save!
      end

      context "for new attachment" do
        subject { journable.last_journal.details }

        it { is_expected.to have_key attachment_id }

        it { expect(subject[attachment_id]).to eq([nil, attachment.filename]) }
      end

      context "when attachment saved w/o change" do
        it { expect { attachment.save! }.not_to change(Journal, :count) }
      end
    end

    # These examples also guard the callback order between the
    # WorkPackage::Versions and WorkPackage::Journalized concerns: the journal
    # snapshots table state during the save, so it only captures the version
    # associations if they are persisted by the earlier after_save callback.
    context "on target version changes", with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) do
        create(:work_package)
      end

      def set_target_versions(versions)
        journable.target_version_ids_replacements = versions.map(&:id)
        journable.save!
      end

      context "when setting target versions" do
        it "creates a new journal listing the versions in the details" do
          expect { set_target_versions([version, other_version]) }
            .to change { journable.journals.count }.by(1)

          expect(journable.last_journal.details["target_versions"])
            .to eq([nil, [version.id, other_version.id].sort.join(",")])
        end

        it "touches the journable to match the journal's timestamp" do
          expect { set_target_versions([version]) }
            .to change { journable.reload.updated_at }

          expect(journable.updated_at).to eq(journable.last_journal.updated_at)
        end
      end

      context "when replacing a target version" do
        before do
          set_target_versions([version])
        end

        it "creates a new journal with the old and new versions in the details" do
          expect { set_target_versions([other_version]) }
            .to change { journable.journals.count }.by(1)

          expect(journable.last_journal.details["target_versions"])
            .to eq([version.id.to_s, other_version.id.to_s])
        end
      end

      context "when removing all target versions" do
        before do
          set_target_versions([version])
        end

        it "creates a new journal with an empty new value in the details" do
          expect { set_target_versions([]) }
            .to change { journable.journals.count }.by(1)

          expect(journable.last_journal.details["target_versions"])
            .to eq([version.id.to_s, nil])
        end
      end

      context "when saving with unchanged target versions" do
        before do
          set_target_versions([version])
        end

        it "creates no journal and does not touch the journable" do
          expect { set_target_versions([version]) }
            .to not_change { journable.journals.count }
            .and(not_change { journable.reload.updated_at })
        end
      end

      context "within aggregation time", with_settings: { journal_aggregation_time_minutes: 5 } do
        # The initial journal lies outside the aggregation window so that only
        # the journals created by the examples can aggregate with each other.
        shared_let(:journable) do
          create(:work_package,
                 subject: "Initial subject",
                 journals: { 10.minutes.ago => { user: } })
        end

        context "when changing target versions again" do
          before do
            set_target_versions([version])
          end

          it "aggregates into the previous journal with cumulative details" do
            expect { set_target_versions([version, other_version]) }
              .not_to change { journable.journals.count }

            expect(journable.last_journal.details["target_versions"])
              .to eq([nil, [version.id, other_version.id].sort.join(",")])
          end
        end

        context "when changing target versions shortly after another change" do
          before do
            journable.update!(subject: "Changed subject")
          end

          it "aggregates into one journal capturing both changes" do
            expect { set_target_versions([version]) }
              .not_to change { journable.journals.count }

            expect(journable.last_journal.details["subject"])
              .to eq(["Initial subject", "Changed subject"])
            expect(journable.last_journal.details["target_versions"])
              .to eq([nil, version.id.to_s])
          end
        end
      end

      context "on work package creation" do
        it "includes the target versions in the initial journal's details" do
          journable = build(:work_package)
          journable.target_version_ids_replacements = [version.id]
          journable.save!

          expect(journable.last_journal.details["target_versions"])
            .to eq([nil, version.id.to_s])
        end
      end

      context "when setting target versions via the replacements" do
        it "does not additionally journal the mirrored version_id" do
          set_target_versions([version])

          expect(journable.last_journal.details)
            .not_to have_key("version_id")
        end
      end
    end

    context "on observed in version changes", with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) do
        create(:work_package)
      end

      def set_observed_in_versions(versions)
        journable.observed_in_version_ids_replacements = versions.map(&:id)
        journable.save!
      end

      context "when setting observed in versions" do
        it "creates a new journal listing the versions in the details" do
          expect { set_observed_in_versions([version, other_version]) }
            .to change { journable.journals.count }.by(1)

          expect(journable.last_journal.details["observed_in_versions"])
            .to eq([nil, [version.id, other_version.id].sort.join(",")])
        end
      end

      context "when replacing an observed in version" do
        before do
          set_observed_in_versions([version])
        end

        it "creates a new journal with the old and new versions in the details" do
          expect { set_observed_in_versions([other_version]) }
            .to change { journable.journals.count }.by(1)

          expect(journable.last_journal.details["observed_in_versions"])
            .to eq([version.id.to_s, other_version.id.to_s])
        end
      end

      context "when removing all observed in versions" do
        before do
          set_observed_in_versions([version])
        end

        it "creates a new journal with an empty new value in the details" do
          expect { set_observed_in_versions([]) }
            .to change { journable.journals.count }.by(1)

          expect(journable.last_journal.details["observed_in_versions"])
            .to eq([version.id.to_s, nil])
        end
      end

      context "when saving with unchanged observed in versions" do
        before do
          set_observed_in_versions([version])
        end

        it "creates no journal and does not touch the journable" do
          expect { set_observed_in_versions([version]) }
            .to not_change { journable.journals.count }
            .and(not_change { journable.reload.updated_at })
        end
      end
    end

    # Journal creation (the SQL differ gated by JOURNALED_KINDS) and rendering
    # (the per-kind details) are independent implementations. A kind journaled
    # without a matching detail would create journals that display no change.
    context "on version changes of any journaled kind",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) { create(:work_package) }

      it "journals only kinds the version associations define" do
        expect(Journals::CreateService::WorkPackageVersion::JOURNALED_KINDS)
          .to all(be_in(WorkPackageVersion.kinds.keys))
      end

      it "renders a detail for every journaled kind" do
        Journals::CreateService::WorkPackageVersion::JOURNALED_KINDS.each do |kind|
          journable.public_send(:"#{kind}_version_ids_replacements=", [version.id])

          expect { journable.save! }
            .to change { journable.journals.count }.by(1)

          expect(journable.last_journal.details)
            .to have_key("#{kind}_versions"),
                "journaled kind '#{kind}' creates journals but renders no detail for them"
        end
      end
    end

    context "on custom value changes" do
      # The explicit id is needed so that the accessors ('custom_field_1') can be used
      shared_let(:custom_field) do
        create(:boolean_wp_custom_field, id: 1) do |custom_field|
          project.work_package_custom_fields << custom_field
          type.default_variant.custom_fields << custom_field
        end
      end

      context "when setting a custom value" do
        shared_let(:journable) do
          create(:work_package,
                 project:,
                 type:,
                 journals: {
                   1.day.ago => { user: }
                 })
        end

        include_examples "journaled values for",
                         new_values_set: {
                           "custom_field_1" => true
                         },
                         expected_values: {
                           "custom_fields_1" => [nil, "t"]
                         },
                         expect_new_journal: true
      end

      context "when modifying a custom value" do
        shared_let(:journable) do
          create(:work_package,
                 project:,
                 type:,
                 custom_field_1: false,
                 journals: {
                   1.day.ago => { user: }
                 })
        end

        include_examples "journaled values for",
                         new_values_set: {
                           "custom_field_1" => true
                         },
                         expected_values: {
                           "custom_fields_1" => %w[f t]
                         },
                         expect_new_journal: true
      end

      context "when a custom value is removed" do
        shared_let(:journable) do
          create(:work_package,
                 project:,
                 type:,
                 custom_field_1: false,
                 journals: {
                   1.day.ago => { user: }
                 })
        end

        include_examples "journaled values for",
                         new_values_set: {
                           "custom_field_1" => nil
                         },
                         expected_values: {
                           "custom_fields_1" => ["f", nil]
                         },
                         expect_new_journal: true
      end

      context "when nothing changed" do
        shared_let(:journable) do
          create(:work_package,
                 project:,
                 type:,
                 custom_field_1: false,
                 journals: {
                   5.days.ago => { user: }
                 })
        end

        include_examples "no journaled value changes for",
                         new_values_set: {}
      end

      context "when nothing changed and a custom field is added after work package creation" do
        shared_let(:journable) do
          create(:work_package,
                 project:,
                 type:,
                 journals: {
                   5.days.ago => { user: }
                 }) do
            create(:boolean_wp_custom_field, id: 2) do |cf|
              project.work_package_custom_fields << cf
              type.default_variant.custom_fields << cf
            end
          end
        end

        include_examples "no journaled value changes for",
                         new_values_set: {}
      end

      context "when nothing changed and the work package has multiple values for the same custom field" do
        shared_let(:list_cf) do
          create(:list_wp_custom_field, id: 2, possible_values: %w[A B C D]) do |cf|
            project.work_package_custom_fields << cf
            type.default_variant.custom_fields << cf
          end
        end

        shared_let(:journable) do
          create(:work_package,
                 project:,
                 type:,
                 custom_field_1: true,
                 custom_field_2: [list_cf.custom_options.find_by(value: "A"),
                                  list_cf.custom_options.find_by(value: "D")],
                 journals: {
                   5.days.ago => { user: },
                   4.days.ago => { user:, notes: "First comment" }
                 })
        end

        include_examples "no journaled value changes for",
                         new_values_set: {}
      end
    end

    context "on file link changes", with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:file_link) { build(:file_link) }
      let(:file_link_id) { "file_links_#{file_link.id}" }

      shared_let(:journable) do
        create(:work_package)
      end

      before do
        journable.file_links << file_link
        journable.save!
      end

      context "for the new file link" do
        subject(:journal_details) { journable.last_journal.details }

        it { is_expected.to have_key file_link_id }

        it {
          expect(journal_details[file_link_id])
            .to eq([nil, { "link_name" => file_link.origin_name, "storage_name" => nil }])
        }
      end

      context "when file link saved w/o change" do
        it {
          expect do
            file_link.save
            journable.save_journals
          end.not_to change(Journal, :count)
        }
      end
    end

    context "on only journal notes adding outside of aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 10.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_notes" => "Some notes"
                       },
                       expected_values: {},
                       expected_notes: "Some notes",
                       expect_new_journal: true
    end

    context "on only journal notes adding within aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_notes" => "Some notes"
                       },
                       expected_values: {},
                       expected_notes: "Some notes",
                       expect_new_journal: false
    end

    context "on only journal notes adding within aggregation time as a different user" do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 10.minutes.ago => { user: other_user },
                 4.minutes.ago => { user: other_user }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_notes" => "Some notes"
                       },
                       expected_values: {},
                       expected_notes: "Some notes",
                       expect_new_journal: true
    end

    context "on only journal notes adding within aggregation time with the last journal already having a note" do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user:, notes: "The former note" }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_notes" => "Some notes"
                       },
                       expected_values: {},
                       expected_notes: "Some notes",
                       expect_new_journal: true
    end

    context "on changes within aggregation time for a work package with a journal with notes" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               journals: {
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user:, notes: "The former note" }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject"
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"]
                       },
                       expected_notes: "The former note",
                       expect_new_journal: false
    end

    context "on mixed journal notes and attribute adding outside of aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               journals: {
                 10.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject",
                         "journal_notes" => "Some notes"
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"]
                       },
                       expected_notes: "Some notes",
                       expect_new_journal: true
    end

    context "on only journal cause adding within aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 # Adding a second journal (even if it is empty) to avoid the changes
                 # from the wp creation to mess with the expected values.
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_cause" => {
                           "type" => "The good cause",
                           "some_reference" => 42
                         }
                       },
                       expected_values: {},
                       expected_cause: {
                         "type" => "The good cause",
                         "some_reference" => 42
                       },
                       expect_new_journal: false
    end

    context "on adding a different cause within aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 4.minutes.ago => { user:, cause: "XYZ" }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_cause" => "ABC"
                       },
                       expected_values: {},
                       expected_cause: "ABC",
                       expect_new_journal: true
    end

    context "on adding the same cause within aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               journals: {
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user:, cause: "ABC" }
               })
      end

      # Adding the change to subject here to show that the whole change is aggregated
      include_examples "journaled values for",
                       new_values_set: {
                         "journal_cause" => "ABC",
                         "subject" => "Changed subject"
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"]
                       },
                       expected_cause: "ABC",
                       expect_new_journal: false
    end

    context "on mixed journal cause, notes and attribute adding outside of aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               journals: {
                 10.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject",
                         "journal_notes" => "Some notes",
                         "journal_cause" => {
                           "type" => "The good cause",
                           "some_reference" => 42
                         }
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"]
                       },
                       expected_notes: "Some notes",
                       expected_cause: {
                         "type" => "The good cause",
                         "some_reference" => 42
                       },
                       expect_new_journal: true
    end

    context "on mixed journal cause, notes and attribute adding within aggregation time" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               journals: {
                 10.minutes.ago => { user: },
                 4.minutes.ago => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject",
                         "journal_notes" => "Some notes",
                         "journal_cause" => {
                           "type" => "The good cause",
                           "some_reference" => 42
                         }
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"]
                       },
                       expected_notes: "Some notes",
                       expected_cause: {
                         "type" => "The good cause",
                         "some_reference" => 42
                       },
                       expect_new_journal: false
    end

    context "on mixed journal cause, notes and attribute adding within aggregation time as a different user" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject",
               journals: {
                 10.minutes.ago => { user: other_user },
                 4.minutes.ago => { user: other_user }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "subject" => "Changed subject",
                         "journal_notes" => "Some notes",
                         "journal_cause" => {
                           "type" => "The good cause",
                           "some_reference" => 42
                         }
                       },
                       expected_values: {
                         "subject" => ["Initial subject", "Changed subject"]
                       },
                       expected_notes: "Some notes",
                       expected_cause: {
                         "type" => "The good cause",
                         "some_reference" => 42
                       },
                       expect_new_journal: true
    end

    context "on only journal notes adding with the most recent journal timestamped ahead of the database clock",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 10.minutes.from_now => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_notes" => "Some notes"
                       },
                       expected_values: {},
                       expected_notes: "Some notes",
                       expect_new_journal: true
    end

    context "on only journal notes adding when the journable has been touched in the database since it was loaded",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) do
        create(:work_package)
      end

      before do
        described_class.where(id: journable.id).update_all(updated_at: 10.minutes.from_now)
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_notes" => "Some notes"
                       },
                       expected_values: {},
                       expected_notes: "Some notes",
                       expect_new_journal: true,
                       expect_journable_update_at_changed: false
    end

    context "on only journal cause adding with the most recent journal timestamped ahead of the database clock",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) do
        create(:work_package,
               journals: {
                 10.minutes.from_now => { user: }
               })
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_cause" => "ABC"
                       },
                       expected_values: {},
                       expected_cause: "ABC",
                       expect_new_journal: true
    end

    context "on only journal cause adding when the journable has been touched in the database since it was loaded",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:journable) do
        create(:work_package)
      end

      before do
        described_class.where(id: journable.id).update_all(updated_at: 10.minutes.from_now)
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_cause" => "ABC"
                       },
                       expected_values: {},
                       expected_cause: "ABC",
                       expect_new_journal: true,
                       expect_journable_update_at_changed: false
    end

    context "when aggregation leads to an empty change (changing back and forth)",
            with_settings: { journal_aggregation_time_minutes: 1 } do
      shared_let(:journable) do
        create(:work_package,
               :created_in_past,
               created_at: 5.minutes.ago,
               project_id: project.id,
               type:,
               description: "Description",
               priority:,
               status:,
               duration: 1)
      end

      let(:other_status) { create(:status) }

      before do
        journable.status = other_status
        journable.save!
        journable.status = status
        journable.save!
      end

      it "creates a new journal" do
        expect(journable.journals.count).to be 2
      end

      it "has the old state in the last journal`s data" do
        expect(journable.journals.last.data.status_id).to be status.id
      end
    end

    context "on changes to newline characters" do
      context "when outside of the aggregation time" do
        shared_let(:journable) do
          create(:work_package,
                 description: "Description\n\nwith newlines\n\nembedded",
                 journals: {
                   1.day.ago => { user: }
                 })
        end

        include_examples "journaled values for",
                         new_values_set: {
                           "description" => "New description"
                         },
                         expected_values: {
                           "description" => ["Description\n\nwith newlines\n\nembedded", "New description"]
                         },
                         expect_new_journal: true

        context "when multiple values are changed and the change to description is only a newline change" do
          shared_let(:journable) do
            create(:work_package,
                   description: "Description\r\n\r\nwith newlines\r\n\r\nembedded",
                   subject: "Original subject",
                   journals: {
                     1.day.ago => { user: }
                   })
          end

          include_examples "journaled values for",
                           new_values_set: {
                             "description" => "Description\r\n\r\nwith newlines\r\n\r\nembedded",
                             "subject" => "New subject"
                           },
                           expected_values: {
                             "subject" => ["Original subject", "New subject"]
                           },
                           expect_new_journal: true
        end

        context "when there is a legacy journal containing non-escaped newlines" do
          shared_let(:journable) do
            create(:work_package,
                   description: "Description\r\n\r\nwith newlines\r\n\r\nembedded",
                   journals: {
                     3.minutes.ago => { user: }
                   })
          end

          include_examples "no journaled value changes for",
                           new_values_set: {
                             "description" => "Description\n\nwith newlines\n\nembedded"
                           },
                           # The value of description does change which is what causes update_at to change
                           expect_journable_update_at_changed: true
        end
      end
    end

    # The below test was failing with the following error:
    # ERROR:  new row for relation "journals" violates check constraint "journals_validity_period_not_empty" (PG::CheckViolation)
    # DETAIL:  Failing row contains (1178, WorkPackage, 481, 1252, , 2025-12-04 07:58:21.028586+00, 1,
    #          2025-12-04 07:58:21.028586+00, Journal::WorkPackageJournal, 833, {}, empty, f).
    context "on adding two notes right after creation" do
      shared_let(:journable) do
        create(:work_package,
               subject: "Initial subject") do |wp|
          wp.add_journal(user:, notes: "First comment")
          wp.save!
        end
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "journal_notes" => "Second comment"
                       },
                       expected_values: {},
                       expected_notes: "Second comment",
                       expect_new_journal: true

      context "when then changing an attribute" do
        before do
          journable.add_journal(user:, notes: "Second comment")
          journable.save!
        end

        include_examples "journaled values for",
                         new_values_set: {
                           "subject" => "Changed subject"
                         },
                         expected_values: {
                           "subject" => ["Initial subject", "Changed subject"]
                         },
                         expected_notes: "Second comment",
                         expect_new_journal: false

        context "when now adding a note" do
          before do
            journable.update!(subject: "Changed subject")
          end

          include_examples "journaled values for",
                           new_values_set: {
                             "journal_notes" => "Third comment"
                           },
                           expected_values: {},
                           expected_notes: "Third comment",
                           expect_new_journal: true

          context "when now adding another note" do
            before do
              journable.add_journal(user:, notes: "Third comment")
            end

            include_examples "journaled values for",
                             new_values_set: {
                               "journal_notes" => "Fourth comment"
                             },
                             expected_values: {},
                             expected_notes: "Fourth comment",
                             expect_new_journal: true
          end
        end
      end
    end

    context "on having a broken journal chain (e.g. because of legacy data)",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:journable) do
        create(:work_package,
               description: "Initial description") do |wp|
          wp.add_journal(notes: "Note to be deleted")
          wp.save!
          wp.update!(description: "Changed description")
          wp.journals.reload.find_by(notes: "Note to be deleted").destroy!
        end
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "description" => "Changed again description"
                       },
                       expected_values: {
                         "description" => ["Changed description", "Changed again description"]
                       },
                       expect_new_journal: true
    end
  end

  describe "#destroy" do
    let(:project) { create(:project) }
    let(:type) { create(:type) }
    let(:custom_field) do
      create(:integer_wp_custom_field) do |cf|
        project.work_package_custom_fields << cf
        type.default_variant.custom_fields << cf
      end
    end
    let(:work_package) do
      create(:work_package,
             project:,
             type:,
             custom_field_values: { custom_field.id => 5 },
             attachments: [attachment],
             file_links: [file_link])
    end
    let(:attachment) { build(:attachment) }
    let(:file_link) { build(:file_link) }

    let!(:journal) { work_package.journals.first }
    let!(:customizable_journals) { journal.customizable_journals }
    let!(:attachable_journals) { journal.attachable_journals }
    let!(:storable_journals) { journal.storable_journals }

    before do
      work_package.destroy
    end

    it "removes the journal" do
      expect(Journal.find_by(id: journal.id))
        .to be_nil
    end

    it "removes the journal data" do
      expect(Journal::WorkPackageJournal.find_by(id: journal.data_id))
        .to be_nil
    end

    it "removes the customizable journals" do
      expect(Journal::CustomizableJournal.find_by(id: customizable_journals.map(&:id)))
        .to be_nil
    end

    it "removes the attachable journals" do
      expect(Journal::AttachableJournal.find_by(id: attachable_journals.map(&:id)))
        .to be_nil
    end

    it "removes the storable journals" do
      expect(Journal::StorableJournal.find_by(id: attachable_journals.map(&:id)))
        .to be_nil
    end
  end

  describe "#journals.internal_visible" do
    let(:work_package) { create(:work_package) }
    let(:admin) { create(:admin) }
    let(:user) { create(:user) }

    let!(:internal_note) do
      create(:work_package_journal,
             user: admin,
             notes: "First comment by admin",
             journable: work_package,
             internal: true,
             version: 2)
    end

    let!(:public_note) do
      create(:work_package_journal,
             user:,
             notes: "First comment by user",
             journable: work_package,
             internal: false,
             version: 3)
    end

    subject(:journals) { work_package.journals.internal_visible }

    before do
      login_as user
    end

    context "when enterprise token allows internal_comments", with_ee: [:internal_comments] do
      context "and setting is enabled for the project" do
        before do
          work_package.project.enabled_internal_comments = true
          work_package.project.save!
        end

        context "when the user cannot see internal journals" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_in_work_package :view_work_packages, work_package:
            end
          end

          it "does not return the internal journal" do
            expect(journals.map(&:id)).not_to include(internal_note.id)
            expect(journals.map(&:id)).to include(public_note.id)
          end
        end

        context "when the user can see internal journals" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_in_project(:view_internal_comments, project: work_package.project)
            end
          end

          it "returns all journals" do
            expect(journals.map(&:id)).to include(internal_note.id, public_note.id)
          end
        end
      end

      context "and setting is disabled for the project" do
        before do
          work_package.project.enabled_internal_comments = false
          work_package.project.save!

          mock_permissions_for(user) do |mock|
            mock.allow_in_project(:view_internal_comments, project: work_package.project)
          end
        end

        it "does not return the internal journal" do
          expect(journals.map(&:id)).not_to include(internal_note.id)
          expect(journals.map(&:id)).to include(public_note.id)
        end
      end
    end

    context "when enterprise token does not allow internal_comments" do
      before do
        work_package.project.enabled_internal_comments = true
        work_package.project.save!

        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_internal_comments, project: work_package.project)
        end
      end

      it "does not return the internal journal regardless of permissions and project setting" do
        expect(journals.map(&:id)).not_to include(internal_note.id)
        expect(journals.map(&:id)).to include(public_note.id)
      end
    end
  end
end
