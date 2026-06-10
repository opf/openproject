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

RSpec.describe HealthReports::ReportComponent, type: :component do
  let(:report) do
    # rubocop:disable Naming/VariableNumber
    generate_test_report(
      group_1: %i[success success],
      group_2: %i[skipped skipped],
      group_3: %i[success success warning warning],
      group_4: %i[success failure failure],
      group_5: %i[success failure warning]
    )
    # rubocop:enable Naming/VariableNumber
  end

  subject(:health_report_component) { described_class.new(report, i18n_scope: "test.scope") }

  before do
    render_inline(health_report_component)
  end

  it "renders a summary" do
    expect(page).to have_text("3 checks failed")
    expect(page).to have_text("Some checks failed and the system does not work as expected.")
  end

  it "renders each group separately" do
    expect(page).to have_test_selector("op-health-report--result-group", count: 5)

    summaries = {
      0 => "All checks passed",
      1 => "All checks passed",
      2 => "2 checks returned a warning",
      3 => "2 checks failed",
      4 => "1 check failed"
    }

    page.all(test_selector("op-health-report--result-group")).each_with_index do |group, idx|
      expect(group).to have_text("Group #{idx + 1}")
      expect(group).to have_text(summaries[idx])
    end
  end

  private

  def generate_test_group(group_key, checks)
    group = HealthReport::ResultGroup.new(key: group_key)

    checks.each_with_index do |check, idx|
      key = :"check_#{idx + 1}"
      result = case check
               when :success
                 HealthReport::Result.success(key)
               when :warning
                 HealthReport::Result.warning(key, :"#{key}_warning", nil)
               when :failure
                 HealthReport::Result.failure(key, :"#{key}_failure", nil)
               else
                 HealthReport::Result.skipped(key)
               end

      group.results << result
      allow(I18n).to receive(:t).with("#{group_key}.#{key}", scope: "test.scope").and_return(key.to_s.humanize)
      if result.code.present?
        allow(I18n).to receive(:t).with("errors.#{result.code}", scope: "test.scope")
                                  .and_return(result.code.to_s.humanize)
      end
    end

    group
  end

  def generate_test_report(map)
    allow(I18n).to receive(:t).and_call_original
    report = HealthReport.new

    map.each_pair do |key, values|
      report.results << generate_test_group(key, values)
      allow(I18n).to receive(:t).with("#{key}.header", scope: "test.scope").and_return(key.to_s.humanize)
    end

    report
  end
end
