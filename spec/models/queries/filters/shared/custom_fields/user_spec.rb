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

# Regression #INTERNAL-954: a user is a member of two groups.
# The overlapping membership should not cause a false match between the two groups when filtering.
RSpec.describe Queries::Filters::Shared::CustomFields::User do
  let(:project) { create(:project) }
  let(:type) { project.enabled_types.first }
  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:user) { create(:user, member_with_roles: { project => [role] }) }

  let(:custom_field) do
    create(:user_wp_custom_field, projects: [project], types: [type])
  end

  let(:shared_group_member) { create(:user) }
  let(:group1) { create(:group, members: [shared_group_member]) }
  let(:group2) { create(:group, members: [shared_group_member]) }

  let(:work_package_with_group_value) do
    create(:work_package, project:, type:).tap do |wp|
      create(:custom_value, custom_field:, customized: wp, value: group1.id.to_s)
    end
  end

  let(:work_package_with_user_value) do
    create(:work_package, project:, type:).tap do |wp|
      create(:custom_value, custom_field:, customized: wp, value: shared_group_member.id.to_s)
    end
  end

  current_user { user }

  before do
    create(:member, project:, principal: group1, roles: [role])
    create(:member, project:, principal: group2, roles: [role])
    create(:member, project:, principal: shared_group_member, roles: [role])
  end

  def results_for(filter_value)
    query = build_stubbed(:query, project:)
    query.add_filter(custom_field.column_name.to_sym, "=", [filter_value.to_s])
    query.results.work_packages
  end

  context "when filtering by the group actually set on the custom field" do
    it "returns the work package" do
      expect(results_for(group1.id)).to contain_exactly(work_package_with_group_value)
    end
  end

  context "when filtering by a different group that shares a member with the group set on the custom field" do
    it "does not return the work package" do
      work_package_with_group_value

      expect(results_for(group2.id)).to be_empty
    end
  end

  context "when filtering by a group whose member is set as the (user) custom field value" do
    it "returns the work package, since the CF's user is a member of the filtered group" do
      expect(results_for(group1.id)).to contain_exactly(work_package_with_user_value)
    end
  end

  context "when filtering by a user who is a member of the group set as the custom field value" do
    it "returns the work package, since the filtered user is a member of the CF's group" do
      expect(results_for(shared_group_member.id)).to contain_exactly(work_package_with_group_value)
    end
  end
end
