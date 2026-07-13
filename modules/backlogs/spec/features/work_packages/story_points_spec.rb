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

RSpec.describe "Work packages having story points", :js do
  before do
    login_as current_user
  end

  let(:current_user) { create(:admin) }
  let(:project) do
    create(:project,
           enabled_module_names: %w(work_package_tracking backlogs))
  end

  describe "showing the story points on the work package show page" do
    let(:story_points) { 42 }
    let(:work_package_with_story_points) do
      create(:work_package,
             author: current_user,
             project:,
             story_points:)
    end

    it "is displayed" do
      wp_page = Pages::FullWorkPackage.new(work_package_with_story_points)

      wp_page.visit!
      wp_page.expect_subject

      wp_page.expect_attributes storyPoints: story_points
    end
  end
end
