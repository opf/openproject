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
  let(:results) do
    [
      HealthReport::ResultGroup.new(key: :configuration,
                                    results: [HealthReport::Result.success(:url_valid),
                                              HealthReport::Result.success(:credentials_present)]),
      HealthReport::ResultGroup.new(key: :authorization,
                                    results: [HealthReport::Result.failure(:credentials_accepted, :credentials_rejected, nil),
                                              HealthReport::Result.skipped(:administrator)])
    ]
  end

  let(:report) { jira.health_reports.create!(results:) }

  before do
    render_inline(described_class.new(health_report_id: report.id))
  end

  it "names the failed check" do
    expect(page).to have_css("h2", text: "Connection check failed")
    expect(page).to have_text("The configuration is saved, but the check Credentials accepted failed.")
    expect(page).to have_css("strong", text: "Credentials accepted")
  end

  it "offers to fix the configuration or to continue to the configuration page" do
    expect(page).to have_button("Fix configuration")
    expect(page).to have_css("form[action='/admin/import/jira/#{jira.id}'][method='get'] button",
                             text: "Continue anyway")
  end

  it "opens on its own and stays out of the page cache, like a flash message" do
    expect(page).to have_css("dialog[data-controller~='auto-show-dialog'][data-turbo-temporary]")
  end
end
