# --copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2022 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe User, '.allowed_members' do
  shared_let(:project) { create(:project, public: false) }

  let(:user) { member.principal }
  let(:anonymous) { build(:anonymous) }
  let(:project2) { build(:project, public: false) }
  let(:role) { build(:role) }
  let(:member) do
    build(:member,
          project:,
          roles: [role])
  end

  let(:action) { :view_work_packages }

  subject(:allowed) do
    described_class.allowed(action, project)
  end

  before do
    Role.anonymous
    Role.non_member
    user.save!
    anonymous.save!
  end

  context 'without the project being public
           with the user being member in the project
           with the role having the necessary permission' do
    before do
      role.add_permission! action

      member.save!
    end

    it 'returns the user' do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context 'without the project being public
           without the user being member in the project
           with the user being admin' do
    before do
      user.update_attribute(:admin, true)
    end

    it 'returns the user' do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to be_empty
    end
  end

  context 'with the project being public
           with the user being member in the project
           with the role having the necessary permission' do
    before do
      project.update_attribute(:public, true)

      role.add_permission! action

      member.save!
    end

    it 'returns the user' do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context 'with the project being public
           without the user being member in the project
           with the role having the necessary permission' do
    before do
      project.update_attribute(:public, true)

      role.add_permission! action
    end

    it 'returns the user' do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to be_empty
    end
  end
end
