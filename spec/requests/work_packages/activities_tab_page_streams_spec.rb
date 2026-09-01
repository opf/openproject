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

RSpec.describe "Work package activity page streams", type: :rails_request do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:, author: user) }

  before { login_as(user) }

  def get_page(page:, filter: :all)
    get page_streams_work_package_activities_path(work_package),
        params: { page:, filter: },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def page_replacement(page)
    target = "work-packages-activities-tab-journals-page-component-#{page}"
    expect(response).to have_http_status(:ok)
    stream = Nokogiri::HTML5.fragment(response.body).at_css("turbo-stream[action='replace'][target='#{target}']")
    expect(stream).to be_present
    replacement = stream.at_css("template ##{target}")
    expect(replacement).to be_present
    replacement
  end

  it "replaces a page that has become empty after the activity list shrinks" do
    get_page(page: 2)

    expect(page_replacement(2).css("[data-test-selector^='op-wp-journal-entry-']")).to be_empty
  end

  it "replaces an empty comments page" do
    get_page(page: 1, filter: :only_comments)

    expect(page_replacement(1).css("[data-test-selector^='op-wp-journal-entry-']")).to be_empty
  end

  it "renders the work package creation on a populated page" do
    get_page(page: 1)

    expect(page_replacement(1).text).to include("created this on")
  end
end
