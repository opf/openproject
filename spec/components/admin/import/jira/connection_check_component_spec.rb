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

RSpec.describe Admin::Import::Jira::ConnectionCheckComponent, type: :component do
  let(:jira) { create(:jira) }
  let(:failed_check) do
    [HealthReport::ResultGroup.new(key: :authorization,
                                   results: [HealthReport::Result.failure(:administrator, :not_administrator, nil)])]
  end

  context "with a new configuration" do
    before { render_inline(described_class.new(build(:jira))) }

    it "says it was not checked yet" do
      expect(page).to have_text("Not checked yet.")
      expect(page).to have_css("button[form='jira-configuration-form'][formaction='/admin/import/jira/test_connection']",
                               text: "Test Connection")
    end
  end

  context "with the stored report of the configuration" do
    before { jira.health_reports.create!(results: failed_check) }

    it "shows the report with the time of the check" do
      render_inline(described_class.new(jira))

      expect(page).to have_text("Last check:")
      expect(page).to have_text("ERR_NOT_ADMINISTRATOR")
      expect(page).to have_css("button[formaction='/admin/import/jira/#{jira.id}/test_connection']")
    end
  end

  context "with a report of the form values" do
    before { render_inline(described_class.new(jira, report: jira.health_reports.build(results: failed_check))) }

    it "says that the checked values are not saved" do
      expect(page).to have_text("Checked the values in the form. They are not saved yet.")
      expect(page).to have_text("ERR_NOT_ADMINISTRATOR")
    end
  end
end
