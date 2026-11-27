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

RSpec.describe "Cost type projects", :skip_csrf,
               type: :rails_request,
               with_settings: { per_page_options: "1,20" } do
  shared_let(:cost_type) { create(:cost_type, for_all_projects: false) }
  shared_let(:projects) { create_list(:project, 3) }

  current_user { create(:admin) }

  before do
    projects.each { CostTypesProject.create!(cost_type:, project: it) }
  end

  def remove_href(page:)
    %r{/admin/cost_types/#{cost_type.id}/project\?.*page=#{page}}
  end

  def turbo_fragment
    Capybara.string(Nokogiri::HTML(response.parsed_body).css("turbo-stream template").map(&:inner_html).join)
  end

  it "shows the last page when the requested page is past it", :aggregate_failures do
    get admin_cost_type_projects_path(cost_type, page: 9, per_page: 1)

    expect(response).to have_http_status(:ok)
    expect(page).to have_text("(3 - 3/3)")
    expect(page).to have_link(href: remove_href(page: 3), visible: :all)
  end

  it "keeps the pagination on the projects page after removing a project", :aggregate_failures do
    delete admin_cost_type_project_path(cost_type, page: 1, per_page: 1, cost_types_project: { project_id: projects.first.id }),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
    expect(turbo_fragment).to have_link(href: admin_cost_type_projects_path(cost_type, page: 2), visible: :all)
    expect(turbo_fragment).to have_link(href: remove_href(page: 1), visible: :all)
  end
end
