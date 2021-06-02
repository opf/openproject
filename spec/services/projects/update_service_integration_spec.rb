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

require 'spec_helper'

describe Projects::UpdateService, 'integration', type: :model do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: permissions)
  end
  let(:permissions) do
    %i(edit_project)
  end

  let!(:project) do
    FactoryBot.create(:project,
                      "custom_field_#{custom_field.id}" => 1,
                      status: project_status)
  end
  let(:instance) { described_class.new(user: user, model: project) }
  let(:custom_field) { FactoryBot.create(:int_project_custom_field) }
  let(:project_status) { nil }

  let(:attributes) { {} }
  let(:service_result) do
    instance
      .call(attributes)
  end

  describe '#call' do
    context 'if only a custom field is updated' do
      let(:attributes) do
        { "custom_field_#{custom_field.id}" => 8 }
      end

      it 'touches the project after saving' do
        former_updated_at = Project.pluck(:updated_at).first

        service_result

        later_updated_at = Project.pluck(:updated_at).first

        expect(former_updated_at)
          .not_to eql later_updated_at
      end
    end

    context 'if a new custom field gets a value assigned' do
      let(:custom_field2) { FactoryBot.create(:text_project_custom_field) }

      let(:attributes) do
        { "custom_field_#{custom_field2.id}" => 'some text' }
      end

      it 'touches the project after saving' do
        former_updated_at = Project.pluck(:updated_at).first

        service_result

        later_updated_at = Project.pluck(:updated_at).first

        expect(former_updated_at)
          .not_to eql later_updated_at
      end
    end

    context 'when saving the status as well as the parent' do
      let(:parent_project) { FactoryBot.create(:project, members: { user => parent_role }) }
      let(:parent_role) { FactoryBot.create :role, permissions: %i(add_subprojects) }
      let(:project_status) { FactoryBot.create(:project_status, code: 'on_track') }
      let(:attributes) do
        {
          parent_id: parent_project.id,
          status: {
            code: 'off_track'
          }
        }
      end

      it 'updates both the status as well as the parent' do
        # This is made difficult by awesome_nested_set reloading the project after saving.
        # Because of the reloading, unpersisted changes to status get lost.
        service_result

        project.reload

        expect(project.parent)
          .to eql parent_project

        expect(project.status)
          .to be_off_track
      end
    end
  end
end
