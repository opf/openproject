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

require_relative "../../support/pages/meetings/show"

RSpec.describe "Meetings Export PDF",
               :js, :selenium do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] }).tap do |u|
      u.pref[:time_zone] = "Etc/UTC"

      u.save!
    end
  end
  let(:show_page) { Pages::Meetings::Show.new(meeting) }
  let(:exporter) { instance_double(Meetings::ExportJob) }
  let(:default_expected_params) do
    {
      participants: "1",
      attachments: "0",
      backlog: "0",
      outcomes: "0",
      footer_text: project.name
    }
  end
  let(:expected_params) do
    default_expected_params
  end

  RSpec::Matchers.define :has_mandatory_options do |expected|
    match do |actual|
      options = actual[:options] || {}
      expected.count do |key, value|
        options[key.to_sym] == value
      end == expected.size
    end
  end

  def generate!
    click_link_or_button "Download"
    sleep 0.5 # quick fix: allow the browser to process the action
    retry_block do
      expect(page).to have_no_button("Download", wait: 3)
      show_page.expect_modal "Background job status", wait: 3
    end
  end

  def mock_generating_pdf
    allow(Meetings::ExportJob)
      .to receive(:perform_later)
            .with(has_mandatory_options(expected_params))
            .and_call_original
  end

  before do
    mock_generating_pdf
    login_as user
    show_page.visit!
    show_page.trigger_dropdown_menu_item "Export PDF"
    show_page.expect_modal "Export PDF"
  end

  context "with default options" do
    it "can submit the export dialog with options" do
      expect(show_page).to have_field("pdf_include_participants", checked: true)
      expect(show_page).to have_field("pdf_include_attachments", checked: false)
      expect(show_page).to have_field("pdf_include_backlog", checked: false)
      expect(show_page).to have_field("pdf_include_outcomes", checked: false)
      generate!
    end
  end

  context "with changed options" do
    let(:expected_params) do
      default_expected_params.merge(participants: "0", attachments: "1", backlog: "1", outcomes: "1")
    end

    it "can submit the export dialog with options" do
      show_page.uncheck "pdf_include_participants"
      show_page.check "pdf_include_attachments"
      show_page.check "pdf_include_backlog"
      show_page.check "pdf_include_outcomes"
      expect(show_page).to have_field("pdf_include_participants", checked: false)
      expect(show_page).to have_field("pdf_include_attachments", checked: true)
      expect(show_page).to have_field("pdf_include_backlog", checked: true)
      expect(show_page).to have_field("pdf_include_outcomes", checked: true)
      generate!
    end
  end

  context "with custom footer text" do
    let(:expected_params) do
      default_expected_params.merge(footer_text: "Custom Footer Text")
    end

    it "can submit the export dialog with options" do
      show_page.fill_in "pdf_footer_text", with: "Custom Footer Text"
      generate!
    end
  end
end
