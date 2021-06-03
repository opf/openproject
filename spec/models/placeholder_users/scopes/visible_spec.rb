#-- encoding: UTF-8

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

describe PlaceholderUsers::Scopes::Visible, type: :model do
  describe '.visible' do
    shared_let(:project) { FactoryBot.create :project }
    shared_let(:other_project) { FactoryBot.create :project }
    shared_let(:role) { FactoryBot.create :role, permissions: %i[manage_members] }

    shared_let(:other_project_placeholder) { FactoryBot.create :placeholder_user, member_in_project: other_project, member_through_role: role }
    shared_let(:global_placeholder) { FactoryBot.create :placeholder_user }

    subject { ::PlaceholderUser.visible.to_a }

    context 'when user has manage_members permission' do
      current_user { FactoryBot.create :user, member_in_project: project, member_through_role: role }

      it 'sees all users' do
        expect(subject).to match_array [other_project_placeholder, global_placeholder]
      end
    end

    context 'when user has no manage_members permission, but it is in other project' do
      current_user { FactoryBot.create :user, member_in_project: other_project, member_with_permissions: %i[view_work_packages] }

      it 'sees the other user in the same project' do
        expect(subject).to match_array [other_project_placeholder]
      end
    end

    context 'when user has no permission' do
      current_user { FactoryBot.create :user }

      it 'sees nothing' do
        expect(subject).to match_array []
      end
    end
  end
end
