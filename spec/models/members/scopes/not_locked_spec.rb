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

describe Members::Scopes::NotLocked, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role) }

  let!(:invited_user_member) do
    FactoryBot.create(:member,
                      project: project,
                      roles: [role],
                      principal: FactoryBot.create(:user, status: Principal.statuses[:invited]))
  end
  let!(:registered_user_member) do
    FactoryBot.create(:member,
                      project: project,
                      roles: [role],
                      principal: FactoryBot.create(:user, status: Principal.statuses[:registered]))
  end
  let!(:locked_user_member) do
    FactoryBot.create(:member,
                      project: project,
                      roles: [role],
                      principal: FactoryBot.create(:user, status: Principal.statuses[:locked]))
  end
  let!(:active_user_member) do
    FactoryBot.create(:member,
                      project: project,
                      roles: [role],
                      principal: FactoryBot.create(:user, status: Principal.statuses[:active]))
  end
  let!(:group_member) do
    FactoryBot.create(:member,
                      project: project,
                      roles: [role],
                      principal: FactoryBot.create(:group))
  end

  describe '.fetch' do
    subject { Member.not_locked }

    it 'returns only actual users and groups' do
      expect(subject)
        .to match_array [active_user_member,
                         invited_user_member,
                         registered_user_member,
                         group_member]
    end
  end
end
