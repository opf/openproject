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

RSpec.describe Query::Results, "Shared with user filter integration" do
  shared_let(:project) { create(:project) }
  shared_let(:work_package_role) { create(:work_package_role, permissions: %i[view_work_packages]) }

  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages view_shared_work_packages] })
  end
  shared_let(:shared_with_user) { create(:user) }

  shared_let(:shared_work_package) do
    create(:work_package, project:) do |wp|
      create(:member, user: shared_with_user, project:, entity: wp, roles: [work_package_role])
    end
  end
  shared_let(:other_work_package) { create(:work_package, project:) }

  let(:query) do
    build(:query, user:, project:, show_hierarchies: false).tap do |q|
      q.filters.clear
      filters.each { |field, operator, values| q.add_filter(field, operator, values) }
    end
  end
  let(:query_results) { described_class.new(query) }

  let(:shared_with_user_filter) { ["shared_with_user", "=", [shared_with_user.id.to_s]] }
  let(:status_filter) { ["status_id", "=", [shared_work_package.status_id.to_s, other_work_package.status_id.to_s]] }

  current_user { user }

  context "when the filter is the only one" do
    let(:filters) { [shared_with_user_filter] }

    it "returns only the shared work package" do
      expect(query_results.work_packages)
        .to contain_exactly(shared_work_package)
    end
  end

  context "when another filter follows it" do
    let(:filters) { [shared_with_user_filter, status_filter] }

    it "returns only the shared work package" do
      expect(query_results.work_packages)
        .to contain_exactly(shared_work_package)
    end
  end

  context "when another filter precedes it" do
    let(:filters) { [status_filter, shared_with_user_filter] }

    it "returns only the shared work package" do
      expect(query_results.work_packages)
        .to contain_exactly(shared_work_package)
    end
  end
end
