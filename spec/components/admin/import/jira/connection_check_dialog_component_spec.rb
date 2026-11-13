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

require "rails_helper"

RSpec.describe Admin::Import::Jira::ConnectionCheckDialogComponent, type: :component do
  let(:jira) { create(:jira) }
  let(:configuration_group) do
    HealthReport::ResultGroup.new(key: :configuration,
                                  results: [HealthReport::Result.success(:url_valid),
                                            HealthReport::Result.success(:credentials_present)])
  end
  let(:report) { jira.health_reports.create!(results:) }

  before do
    render_inline(described_class.new(health_report_id: report.id))
  end

  context "when a check failed" do
    let(:results) do
      [
        configuration_group,
        HealthReport::ResultGroup.new(key: :authorization,
                                      results: [HealthReport::Result.failure(:credentials_accepted, :credentials_rejected, nil),
                                                HealthReport::Result.skipped(:administrator)])
      ]
    end

    it "names the failed check" do
      expect(page).to have_css("h2", text: "Connection check failed")
      expect(page).to have_text("The configuration is saved, but the check Credentials accepted failed.")
      expect(page).to have_css("strong", text: "Credentials accepted")
    end

    it "shows a danger icon" do
      expect(page).to have_css(".FeedbackMessage .color-fg-danger")
    end

    it "offers to fix the configuration or to continue to the configuration page" do
      expect(page).to have_button("Fix configuration")
      expect(page).to have_css("form[action='/admin/import/jira/#{jira.id}'][method='get'] button",
                               text: "Continue anyway")
    end
  end

  context "when a check warned and another failed" do
    let(:results) do
      [
        configuration_group,
        HealthReport::ResultGroup.new(
          key: :server,
          results: [HealthReport::Result.success(:reachable),
                    HealthReport::Result.success(:responds_as_jira),
                    HealthReport::Result.warning(:version_supported, :unsupported_version, { "version" => "8.5.0" }),
                    HealthReport::Result.failure(:auth_method_supported, :basic_auth_required, { "version" => "8.5.0" })]
        )
      ]
    end

    it "names the failed check" do
      expect(page).to have_css("h2", text: "Connection check failed")
      expect(page).to have_css("strong", text: "Authentication method")
    end
  end

  context "when a check warned and none failed" do
    let(:results) do
      [
        configuration_group,
        HealthReport::ResultGroup.new(
          key: :server,
          results: [HealthReport::Result.success(:reachable),
                    HealthReport::Result.success(:responds_as_jira),
                    HealthReport::Result.warning(:version_supported, :unsupported_version, { "version" => "12.0.0" }),
                    HealthReport::Result.success(:auth_method_supported)]
        )
      ]
    end

    it "names the check with the warning and asks to proceed at one's own risk" do
      expect(page).to have_css("h2", text: "Connection check warning")
      expect(page).to have_text("The configuration is saved, but the check Supported version reported a warning.")
      expect(page).to have_text("Proceed at your own risk.")
      expect(page).to have_css("strong", text: "Supported version")
      expect(page).to have_css(".FeedbackMessage .color-fg-attention")
    end
  end
end
