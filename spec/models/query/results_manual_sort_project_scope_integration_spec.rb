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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++
require "spec_helper"

RSpec.describe Query::Results, "Manual sort project scope integration" do
  shared_let(:board_project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:invisible_project) { create(:project) }

  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             board_project => [:view_work_packages],
             other_project => [:view_work_packages]
           })
  end

  shared_let(:board_wp) { create(:work_package, project: board_project) }
  shared_let(:other_wp) { create(:work_package, project: other_project) }
  shared_let(:invisible_wp) { create(:work_package, project: invisible_project) }

  let(:query) do
    create(:query, user:, project: board_project).tap do |q|
      q.filters.clear
      [board_wp, other_wp, invisible_wp].each_with_index do |work_package, position|
        OrderedWorkPackage.create(query: q, work_package:, position:)
      end
    end
  end
  let(:query_results) { described_class.new(query) }

  before do
    login_as user
  end

  context "with a manual sort filter" do
    before do
      query.add_filter "manual_sort", "ow", []
    end

    it "includes ordered work packages from other visible projects" do
      expect(query_results.work_packages).to contain_exactly(board_wp, other_wp)
    end

    it "excludes ordered work packages from invisible projects" do
      expect(query_results.work_packages).not_to include(invisible_wp)
    end

    it "narrows to an explicit project filter" do
      query.add_filter "project_id", "=", [other_project.id]

      expect(query_results.work_packages).to contain_exactly(other_wp)
    end
  end

  context "without a manual sort filter" do
    before do
      query.add_filter "status_id", "*", []
    end

    it "keeps the project limit" do
      expect(query_results.work_packages).to contain_exactly(board_wp)
    end
  end
end
