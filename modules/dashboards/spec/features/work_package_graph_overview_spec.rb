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

require_relative "../support/pages/dashboard"

RSpec.describe "Work package overview graph widget on dashboard", :js do
  let!(:type) { create(:type) }
  let!(:priority) { create(:default_priority) }
  let!(:project) { create(:project, types: [type]) }
  let!(:open_status) { create(:default_status) }
  let!(:closed_status) { create(:closed_status) }
  let!(:open_work_package) do
    create(:work_package,
           subject: "Spanning work package",
           project:,
           status: open_status,
           type:,
           author: user,
           responsible: user)
  end
  let!(:closed) do
    create(:work_package,
           subject: "Starting work package",
           project:,
           status: closed_status,
           type:,
           author: user,
           responsible: user)
  end

  let(:permissions) do
    %i[view_work_packages
       view_dashboards
       manage_dashboards]
  end

  let(:role) do
    create(:project_role, permissions:)
  end

  let(:user) do
    create(:user).tap do |u|
      create(:member, project:, user: u, roles: [role])
    end
  end

  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard.visit!
  end

  # As a graph is rendered as a canvas, we have limited abilities to test the widget
  it "can add the widget" do
    sleep(0.1)

    dashboard.add_widget(1, 1, :within, "Work packages overview")

    # As the user lacks the necessary permissions, no widget is preconfigured
    overview_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

    overview_widget.expect_to_span(1, 1, 2, 2)
  end
end
