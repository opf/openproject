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

RSpec.describe WorkPackages::Scopes::WithoutExcludedType do
  let(:user) { create(:admin) }
  let(:included_type) { create(:type, name: "Story") }
  let(:excluded_type) { create(:type, name: "Task") }
  let(:project) do
    create(:project,
           enabled_module_names: %w[backlogs],
           types: [included_type, excluded_type]) do |p|
      p.backlog_excluded_types = [excluded_type]
    end
  end

  current_user { user }

  subject(:visible) { WorkPackage.without_excluded_type }

  describe ".without_excluded_type" do
    it "returns work packages whose type is not excluded in the project" do
      wp_with_included_type = create(:work_package, project:, type: included_type)
      create(:work_package, project:, type: excluded_type)

      expect(visible).to contain_exactly(wp_with_included_type)
    end

    it "considers the excluded type configuration of the project a work package belongs to" do
      project_without_exclusion = create(:project,
                                         enabled_module_names: %w[backlogs],
                                         types: [included_type, excluded_type])

      create(:work_package, type: excluded_type, project:)
      wp_not_excluded_in_other_project = create(:work_package,
                                                type: excluded_type,
                                                project: project_without_exclusion)

      expect(visible).to contain_exactly(wp_not_excluded_in_other_project)
    end

    it "returns all work packages when no types are excluded in the project" do
      project_no_exclusions = create(:project,
                                     enabled_module_names: %w[backlogs],
                                     types: [included_type, excluded_type])

      wp1 = create(:work_package, project: project_no_exclusions, type: included_type)
      wp2 = create(:work_package, project: project_no_exclusions, type: excluded_type)

      expect(visible).to include(wp1, wp2)
    end
  end
end
