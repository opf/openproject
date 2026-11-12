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

RSpec.describe "work package hierarchies for milestones", :js do
  let(:user) { create(:admin) }
  let(:task_type) { create(:type_task) }
  let(:milestone_type) { create(:type_milestone) }
  let(:project) { create(:project, types: [task_type, milestone_type]) }
  let!(:milestone_work_package) { create(:work_package, subject: "milestone_work_package", project:, type: milestone_type) }
  let!(:task_work_package) { create(:work_package, subject: "task_work_package", project:, type: task_type) }
  let(:relations) { Components::WorkPackages::Relations.new }

  before do
    login_as user
  end

  def visit_relations_tab_for(work_package)
    wp_page = Pages::FullWorkPackage.new(work_package)
    wp_page.visit_tab!("relations")
    expect_angular_frontend_initialized
    wp_page.expect_subject
    loading_indicator_saveguard
  end

  it "does not provide links to create new child or add existing work package as child (Regression #28745 and #60512)" do
    # A work package has a menu entry to link or create a child
    visit_relations_tab_for(task_work_package)
    relations.expect_new_relation_type("Create new child")
    relations.expect_new_relation_type("Child")

    # A milestone work package does NOT have a menu entry to link or create a child
    visit_relations_tab_for(milestone_work_package)
    relations.expect_no_new_relation_type("Create new child")
    relations.expect_no_new_relation_type("Child")
  end
end
