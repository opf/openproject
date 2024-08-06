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

RSpec.describe "Work packages having story points", :js, :with_cuprite do
  before do
    login_as current_user
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return("points_burn_direction" => "down",
                                                                       "wiki_template" => "",
                                                                       "story_types" => [story_type.id.to_s],
                                                                       "task_type" => task_type.id.to_s)
  end

  let(:current_user) { create(:admin) }
  let(:project) do
    create(:project,
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:status) { create(:default_status) }
  let(:story_type) { create(:type_feature) }
  let(:task_type) { create(:type_feature) }

  describe "showing the story points on the work package show page" do
    let(:story_points) { 42 }
    let(:story_with_sp) do
      create(:story,
             type: story_type,
             author: current_user,
             project:,
             status:,
             story_points:)
    end

    it "is displayed" do
      wp_page = Pages::FullWorkPackage.new(story_with_sp)

      wp_page.visit!
      wp_page.expect_subject

      wp_page.expect_attributes storyPoints: story_points
    end
  end
end
