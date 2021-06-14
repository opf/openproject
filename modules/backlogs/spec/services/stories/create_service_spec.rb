#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Stories::CreateService, type: :model do
  let(:priority) { FactoryBot.create(:priority) }
  let(:project) do
    project = FactoryBot.create(:project, types: [type_feature])

    FactoryBot.create(:member,
                      principal: current_user,
                      project: project,
                      roles: [role])
    project
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i(add_work_packages manage_subtasks assign_versions) }
  let(:status) { FactoryBot.create(:status) }
  let(:type_feature) { FactoryBot.create(:type_feature) }
  let(:workflow) { FactoryBot.create(:workflow, type: type_feature, old_status: status, role: role) }

  let(:instance) do
    Stories::CreateService
      .new(user: current_user)
  end

  let(:attributes) do
    {
      project: project,
      status: status,
      type: type_feature,
      priority: priority,
      parent_id: story.id,
      remaining_hours: remaining_hours,
      subject: 'some subject'
    }
  end

  let(:version) { FactoryBot.create(:version, project: project) }

  let(:story) do
    project.enabled_module_names += ['backlogs']

    FactoryBot.create(:story,
                      version: version,
                      project: project,
                      status: status,
                      type: type_feature,
                      priority: priority)
  end

  current_user do
    FactoryBot.create(:user)
  end

  before do
    workflow
  end

  subject { instance.call(attributes: attributes) }

  describe "remaining_hours" do
    before do
      subject
    end

    context 'with the story having remaining_hours' do
      let(:remaining_hours) { 15.0 }

      it 'does update the parents remaining hours' do
        expect(story.reload.remaining_hours).to eq(15)
      end
    end

    context 'with the subtask not having remaining_hours' do
      let(:remaining_hours) { nil }

      it 'does not note remaining hours to be changed' do
        expect(story.reload.remaining_hours).to be_nil
      end
    end
  end
end
