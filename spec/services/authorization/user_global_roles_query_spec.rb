#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Authorization::UserGlobalRolesQuery do
  let(:user) { FactoryBot.build(:user) }
  let(:anonymous) { FactoryBot.build(:anonymous) }
  let(:project) { FactoryBot.build(:project, public: false) }
  let(:project2) { FactoryBot.build(:project, public: false) }
  let(:public_project) { FactoryBot.build(:project, public: true) }
  let(:role) { FactoryBot.build(:role) }
  let(:role2) { FactoryBot.build(:role) }
  let(:anonymous_role) { FactoryBot.build(:anonymous_role) }
  let(:non_member) { FactoryBot.build(:non_member) }
  let(:member) {
    FactoryBot.build(:member, project: project,
                               roles: [role],
                               principal: user)
  }
  let(:member2) {
    FactoryBot.build(:member, project: project2,
                               roles: [role2],
                               principal: user)
  }

  describe '.query' do
    before do
      non_member.save!
      anonymous_role.save!
      user.save!
    end

    it 'is a user relation' do
      expect(described_class.query(user, project)).to be_a ActiveRecord::Relation
    end

    context 'w/ the user being a member in a project' do
      before do
        member.save!
      end

      it 'is the member and non member role' do
        expect(described_class.query(user)).to match_array [role, non_member]
      end
    end

    context 'w/ the user being a member in two projects' do
      before do
        member.save!
        member2.save!
      end

      it 'is both member and the non member role' do
        expect(described_class.query(user)).to match_array [role, role2, non_member]
      end
    end

    context 'w/o the user being a member in a project' do
      it 'is the non member role' do
        expect(described_class.query(user)).to match_array [non_member]
      end
    end

    context 'w/ the user being anonymous' do
      it 'is the anonymous role' do
        expect(described_class.query(anonymous)).to match_array [anonymous_role]
      end
    end
  end
end
