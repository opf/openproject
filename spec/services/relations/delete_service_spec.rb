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

RSpec.describe Relations::DeleteService do
  # this mandatory custom field is used to make work packages invalid in tests
  shared_let(:mandatory_custom_field) do
    create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil)
  end
  shared_let(:priority) { create(:priority) }
  shared_let(:type_task) { create(:type_task, default_variant_enabled_in_all_projects: true) }
  shared_let(:type_with_mandatory_cf) do
    create(:type,
           position: type_task.position + 1,
           name: "Type with mandatory custom field",
           custom_fields: [mandatory_custom_field])
  end
  shared_let(:project) do
    create(:project,
           types: [type_task, type_with_mandatory_cf],
           work_package_custom_fields: [mandatory_custom_field])
  end
  shared_let(:status) { create(:status) }
  shared_let(:user) { create(:user) }
  shared_let(:admin) { create(:admin) }

  before_all do
    set_factory_default(:priority, priority)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status)
    set_factory_default(:type, type_task)
    set_factory_default(:user, user)
  end

  shared_let(:admin) { create(:admin) }

  subject(:delete_service_result) do
    described_class.new(user: admin, model: relation_to_delete).call
  end

  context "for predecessors/successors relations" do
    context "when the successor no longer has any predecessors" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSS | scheduling mode | predecessors
        predecessor  | XX      | manual          |
        work_package |   X     | automatic       | predecessor
      TABLE

      let(:relation_to_delete) { _table.relation(predecessor: predecessor) }

      it "removes the relation and switches the work package to manual scheduling mode" do
        expect(delete_service_result).to be_success
        expect(subject.all_results).to contain_exactly(relation_to_delete, work_package)

        expect(work_package.relations.count).to eq 0
        expect_work_packages(WorkPackage.all, <<~TABLE)
          subject      | MTWTFSS | scheduling mode
          predecessor  | XX      | manual
          work_package |   X     | manual
        TABLE
      end

      context "when the successor is invalid (missing required custom field for instance)" do
        before do
          work_package.update_attribute(:type, type_with_mandatory_cf)
        end

        it "still updates correctly" do
          # Note: Since the introduction of #63550, invalid custom fields no longer prevent
          # the work package from being saved. However this test could still be kept as a
          # regression test, by forcing the custom field validation with setting the
          # custom_values_to_validate attribute.
          work_package.custom_values_to_validate = work_package.custom_field_values

          # ensure the work package is invalid as intended
          expect(work_package.schedule_manually).to be false
          expect(work_package).not_to be_valid(:saving_custom_fields)

          expect(delete_service_result).to be_success

          # work package has been changed to manual scheduling though still invalid
          expect(work_package.schedule_manually).to be true
          expect(work_package).not_to be_valid(:saving_custom_fields)
        end
      end
    end

    context "when a successor has two predecessors and the closest relation is deleted" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSS | scheduling mode | predecessors
        predecessor1 | XX      | manual          |
        predecessor2 |    X    | manual          |
        work_package |     X   | automatic       | predecessor1, predecessor2
      TABLE

      let(:relation_to_delete) { _table.relation(predecessor: predecessor2) }

      it "removes the relation and reschedules the successor" do
        expect(delete_service_result).to be_success
        expect(subject.all_results).to contain_exactly(relation_to_delete, work_package)

        expect(work_package.relations.count).to eq 1
        expect_work_packages(WorkPackage.all, <<~TABLE)
          subject      | MTWTFSS | scheduling mode
          predecessor1 | XX      | manual
          predecessor2 |    X    | manual
          # successor has been rescheduled to start right after predecessor1
          work_package |   X     | automatic
        TABLE
      end

      context "when the successor is invalid (missing required custom field for instance)" do
        before do
          work_package.update_attribute(:type, type_with_mandatory_cf)
          work_package.custom_values_to_validate = work_package.custom_field_values
        end

        it "still updates correctly" do
          # ensure the work package is invalid as intended
          expect(work_package.start_date).to eq(_table.friday)
          expect(work_package).not_to be_valid(:saving_custom_fields)

          expect(delete_service_result).to be_success

          # work package has been rescheduled though still invalid
          expect(work_package.start_date).to eq(_table.wednesday)
          expect(work_package).not_to be_valid(:saving_custom_fields)
        end
      end
    end
  end
end
