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

RSpec.describe "Test management cases index", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases] })
  end

  before { login_as(user) }

  it "renders the empty cases stub" do
    get project_test_management_test_cases_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-test-selector="tm-cases-empty"')
  end

  context "with the module disabled" do
    shared_let(:disabled_project) { create(:project, enabled_module_names: []) }
    shared_let(:member) do
      create(:user, member_with_permissions: {
               disabled_project => %i[view_project view_test_cases manage_test_management]
             })
    end

    before { login_as(member) }

    it "denies the cases index" do
      get project_test_management_test_cases_path(disabled_project)

      expect(response.status).to be_in([403, 404])
    end

    it "denies project settings" do
      get project_test_management_project_settings_path(disabled_project)

      expect(response.status).to be_in([403, 404])
    end
  end
end
