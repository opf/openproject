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

require "rails_helper"

RSpec.describe HealthReports::ResultComponent, type: :component do
  let(:group_key) { :base_configuration }

  subject(:result_component) { described_class.new(group: group_key, result: check_result, i18n_scope: "test.scope") }

  before do
    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:t).with("#{group_key}.#{check_result.key}", scope: "test.scope").and_return("Translated check")
    allow(I18n).to receive(:t).with("errors.#{check_result.code}", scope: "test.scope").and_return("Translated error")

    render_inline(result_component)
  end

  context "if check result is successful" do
    let(:check_result) { HealthReport::Result.success(:capabilities_request) }

    it "renders the component" do
      expect(page).to have_text("Translated check")
      expect(page).to have_css(".color-fg-success", text: "Passed")
      expect(page).to have_no_css(".Label")
      expect(page).to have_no_link("More information")
      expect(page).not_to have_test_selector("op-health-report--result-status")
    end
  end

  context "if check result is skipped" do
    let(:check_result) { HealthReport::Result.skipped(:capabilities_request) }

    it "renders the component" do
      expect(page).to have_text("Translated check")
      expect(page).to have_css(".color-fg-attention", text: "Skipped")
      expect(page).to have_no_css(".Label")
      expect(page).to have_no_link("More information")
      expect(page).not_to have_test_selector("op-health-report--result-status")
    end
  end

  context "if check result is a warning" do
    let(:group_key) { :ampf_configuration }
    let(:check_result) do
      HealthReport::Result.warning(:drive_contents, :od_unexpected_content, nil)
    end

    it "renders the component" do
      expect(page).to have_text("Translated check")
      expect(page).to have_css(".color-fg-attention", text: "Warning")
      expect(page).to have_css(".Label", text: "WRN_#{check_result.code.upcase}")
      expect(page).to have_text("Translated error")
      expect(page).to have_link("More information")
      expect(page).to have_test_selector("op-health-report--result-status")
    end
  end

  context "if check result is a failure" do
    let(:check_result) do
      HealthReport::Result.failure(:capabilities_request, :unknown_error, nil)
    end

    it "renders the component" do
      expect(page).to have_text("Translated check")
      expect(page).to have_css(".color-fg-danger", text: "Failed")
      expect(page).to have_css(".Label", text: "ERR_#{check_result.code.upcase}")
      expect(page).to have_text("Translated error")
      expect(page).to have_link("More information")
      expect(page).to have_test_selector("op-health-report--result-status")
    end
  end
end
