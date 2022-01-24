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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe Principals::Scopes::PossibleMember, type: :model do
  let(:project) { create(:project) }
  let(:role) { create(:role) }
  let!(:active_user) { create(:user) }
  let!(:locked_user) { create(:user, status: :locked) }
  let!(:registered_user) { create(:user, status: :registered) }
  let!(:invited_user) { create(:user, status: :invited) }
  let!(:anonymous_user) { create(:anonymous) }
  let!(:placeholder_user) { create(:placeholder_user) }
  let!(:group) { create(:group) }
  let!(:member_user) do
    create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let!(:member_placeholder_user) do
    create(:placeholder_user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let!(:member_group) do
    create(:group,
                      member_in_project: project,
                      member_through_role: role)
  end

  describe '.possible_member' do
    subject { Principal.possible_member(project) }

    it 'returns non locked users, groups and placeholder users not part of the project yet' do
      is_expected
        .to match_array([active_user,
                         registered_user,
                         invited_user,
                         placeholder_user,
                         group])
    end
  end
end
