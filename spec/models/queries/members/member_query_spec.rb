#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

describe Queries::Members::MemberQuery, type: :model do
  let(:admin) { create(:admin) }
  let(:instance) { described_class.new(user: admin) }
  # This is the MemberQuery.default_scope with an admin user
  let(:base_scope) { Member.from(Member.all.distinct, :members).order(id: :desc) }

  # Objects required for testing with filters
  let(:group1) { create(:group) }
  let(:group2) { create(:group) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: %i[edit_project]) }
  let(:member) { create(:member, user: admin, project: project, roles: [role]) }

  # We need to be admin user to get the simplified default_scope from MemberQuery
  before do
    # instance.new uses default_user, and we need an admin to get a default_scope of Member.all
    login_as(admin)
  end

  context 'without filter nor data' do
    describe '#results' do
      # Check that the query SQL is the same as the manual SQL
      it 'is the same as getting all the members' do
        expect(instance.results.to_sql).to eql base_scope.to_sql
      end
    end
  end

  context 'with a user but without filters' do
    before do
      # We need to write the membership to the DB to count results
      member.save
    end

    describe '#results' do
      it 'returns the single test user if no filters are specified' do
        expect(instance.results.count).to eq 1
      end
    end
  end

  # Check for regression of bug #38672 describes a case with group filters
  # and a user being member in two different groups which leads to the user
  # appearing twice.
  context 'with group filter and a user belonging to two groups' do
    let(:instance) { described_class.new(user: admin).where(:group, '=', group1.id) }

    before do
      member.save
      # Add the admin user to the two groups
      Groups::UpdateService.new(user: admin, model: group1).call(user_ids: Array(admin.id))
      Groups::UpdateService.new(user: admin, model: group2).call(user_ids: Array(admin.id))
    end

    describe '#results' do
      it 'returns a single result despite the test user being member of two groups' do
        expect(instance.results.count).to eq 1
      end
    end
  end
end
