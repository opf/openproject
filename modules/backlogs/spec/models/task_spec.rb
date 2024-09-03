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

RSpec.describe Task do
  let(:task_type) { create(:type) }
  let(:default_status) { create(:default_status) }
  let(:project) { create(:project) }
  let(:task) do
    build(:task,
          project:,
          status: default_status,
          type: task_type)
  end

  before do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return({ "task_type" => task_type.id.to_s })
  end

  describe "having custom journables", with_settings: { journal_aggregation_time_minutes: 0 } do
    let(:user) { create(:user) }
    let(:role) do
      create(:project_role, permissions: %i[add_work_packages manage_subtasks manage_work_packages view_work_packages])
    end
    let(:member) { create(:member, principal: user, project:, roles: [role]) }

    before do
      project.members << member
    end

    describe "with unchanged custom field" do
      let(:custom_field) { create(:work_package_custom_field, name: "TestingCustomField", field_format: "text") }

      before do
        project.work_package_custom_fields << custom_field
        task_type.custom_fields << custom_field
      end

      it "must have the same journal when resaved" do
        task.custom_field_values = { custom_field.id => "Example CF text" }
        task.save!

        expect(task.journals.last.customizable_journals.count).to eq 1
        customizable_journal = task.journals.last.customizable_journals.first

        attributes = { id: task.id, parent_id: task.parent_id, status_id: task.status_id }
        result = WorkPackages::UpdateService.new(user:, model: task).call(**attributes)

        expect(result).to be_success
        task.reload

        expect(task.journals.last.customizable_journals.first).to eq customizable_journal
      end
    end

    describe "with attachment" do
      let(:attachment) { build(:attachment) }

      it "must have the same journal when resaved" do
        task.attachments << attachment
        task.save!

        expect(task.journals.last.attachable_journals.count).to eq 1
        attachable_journal = task.journals.last.attachable_journals.first

        attributes = { id: task.id, parent_id: task.parent_id, status_id: task.status_id }
        result = WorkPackages::UpdateService.new(user:, model: task).call(**attributes)

        expect(result).to be_success
        task.reload

        expect(task.journals.last.attachable_journals.first).to eq attachable_journal
      end
    end
  end
end
