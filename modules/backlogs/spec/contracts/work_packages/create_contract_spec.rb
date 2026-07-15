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
require_relative "shared_contract_examples"

RSpec.describe WorkPackages::CreateContract do
  let(:work_package) do
    WorkPackage.new(project: work_package_project,
                    subject: "Some subject",
                    type: work_package_type,
                    priority: work_package_priority,
                    status: work_package_status,
                    story_points: work_package_story_points,
                    sprint: work_package_sprint) do |wp|
      wp.extend(OpenProject::ChangedBySystem)

      wp.change_by_system do
        wp.author = work_package_author
      end
    end
  end

  let(:permissions) do
    %i[
      view_work_packages
      add_work_packages
      manage_sprint_items
      view_sprints
    ]
  end

  it_behaves_like "work package contract with backlogs extensions"
end
