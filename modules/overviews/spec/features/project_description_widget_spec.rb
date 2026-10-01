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

require_relative "../support/pages/dashboard"

RSpec.describe "Project description widget", :js do
  include TestSelectorFinders

  let!(:type) { create(:type) }
  let!(:portfolio) { create(:portfolio, description: "A new description") }
  let!(:open_status) { create(:default_status) }

  let(:permissions) do
    %i[manage_dashboards
       view_members
       view_work_packages
       add_work_packages
       save_queries
       manage_public_queries
       edit_project]
  end

  let(:user) do
    create(:user,
           member_with_permissions: { portfolio => permissions })
  end

  let(:dashboard_page) do
    Pages::Dashboard.new(portfolio)
  end

  let(:overview_page) do
    Pages::Projects::Show.new(portfolio)
  end


  shared_examples_for "adds a project description widget, and edits it correctly" do
    before do
      login_as user

      tested_page.visit!
    end

    it do
      expect(page).to have_current_path(path)

      # Edit the project description
      # Find the editable description field
      description_field = Components::Common::InplaceEditField.new(portfolio, :description)

      # Activate the field for editing
      wait_for_turbo_stream { description_field.open_field }
      wait_for_ckeditor

      # Set a new description
      new_description = "This is a **test** project description with markdown formatting."
      wait_for_turbo_stream { description_field.fill_and_submit_value(name: "project[description]", val: new_description, ckeditor: true) }

      tested_page.expect_and_dismiss_flash message: I18n.t("js.notice_successful_update")

      tested_page.visit!
      wait_for_network_idle
      expect(page).to have_content("This is a test project description with markdown formatting.")

      portfolio.reload
      expect(portfolio.description).to include("This is a **test** project description")
    end
  end


  context "as a user with permission" do
    context "on the dashboard" do
      it_behaves_like "adds a project description widget, and edits it correctly" do
        let(:tested_page) { dashboard_page }
        let(:path) { dashboard_project_overview_path(portfolio) }
        let(:selector) { test_selector("grid-widget-project_description") }
      end
    end

    context "on the overview" do
      it_behaves_like "adds a project description widget, and edits it correctly" do
        let(:tested_page) { overview_page }
        let(:path) { project_overview_path(portfolio) }
        let(:selector) { test_selector("op-overview-widget--project-description") }
      end
    end
  end
end
