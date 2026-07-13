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

require_relative "../spec_helper"

RSpec.describe "GET /cost_reports (CSRF token in query form)", type: :rails_request do
  include OpenProject::Reporting::PluginSpecHelper

  current_user { user }

  let(:user) { create(:user) }
  let(:project) { create(:valid_project) }

  before do
    is_member project, user, %i[view_cost_entries]
  end

  it "embeds a non-empty authenticity_token inside #query_form" do
    get "/cost_reports"

    expect(response).to have_http_status(:ok)

    doc = Nokogiri::HTML(response.body)
    form = doc.at_css("form#query_form")
    expect(form).to be_present

    token_input = form.at_css('input[name="authenticity_token"]')
    expect(token_input).to be_present
    expect(token_input["value"]).to be_present
  end
end
