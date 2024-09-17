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

RSpec.describe "Gantt charts menu",
               :js,
               :selenium do
  let(:user) { create(:admin) }
  let(:enabled_module_names) { %i[work_package_tracking gantt] }
  let(:project) { create(:project, enabled_module_names:) }
  let(:wp_project_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let(:wp_global_timeline) { Pages::WorkPackagesTimeline.new }

  let!(:global_private_query) do
    query = build(:global_query, user_id: user.id)
    query.timeline_visible = true
    query.public = false

    query.save!
    create(:view_gantt,
           query:)

    query
  end

  let!(:global_public_query) do
    query = build(:global_query, user_id: user.id)
    query.timeline_visible = true

    query.save!
    create(:view_gantt,
           query:)

    query
  end

  let!(:global_starred_query) do
    query = build(:global_query, user_id: user.id)
    query.timeline_visible = true
    query.starred = true

    query.save!
    create(:view_gantt,
           query:)

    query
  end

  let!(:private_project_query) do
    query = create(:query_with_view_gantt, user:, project:)
    query.timeline_visible = true

    query.save!
    query
  end

  before do
    login_as(user)
  end

  describe "on the global Gantt charts page" do
    it "shows all queries without a project" do
      wp_global_timeline.visit!
      loading_indicator_saveguard

      # Show global queries only
      expect(page).to have_css(".op-submenu--item-action", text: global_starred_query)
      expect(page).to have_css(".op-submenu--item-action", text: global_public_query)
      expect(page).to have_css(".op-submenu--item-action", text: global_private_query)
      expect(page).to have_no_css(".op-submenu--item-action", text: private_project_query)
    end
  end

  describe "on the project Gantt charts page" do
    it "shows all queries that belong to the project" do
      wp_project_timeline.visit!
      loading_indicator_saveguard

      # Show project queries only
      expect(page).to have_no_css(".op-submenu--item-action", text: global_starred_query)
      expect(page).to have_no_css(".op-submenu--item-action", text: global_public_query)
      expect(page).to have_no_css(".op-submenu--item-action", text: global_private_query)
      expect(page).to have_css(".op-submenu--item-action", text: private_project_query)
    end
  end
end
