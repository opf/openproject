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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe LlmConnections::SidePanel::HealthStatusComponent, type: :component do
  let(:connection) { create(:llm_connection) }

  def store_report(*group_keys)
    results = group_keys.map do |key|
      HealthReport::ResultGroup.new(key:, results: [HealthReport::Result.success(:check)])
    end

    connection.health_reports.create!(results:)
  end

  it "offers to run the checks when none have run" do
    render_inline(described_class.new(connection))

    expect(page).to have_text("This connection has not been checked yet.")
  end

  it "reads the latest report once per render" do
    store_report(:configuration, :server)
    allow(connection).to receive(:latest_health_report).and_call_original

    render_inline(described_class.new(connection))

    expect(connection).to have_received(:latest_health_report).once
    expect(page).to have_test_selector("llm-connection--health-summary")
  end

  it "says when the report includes an inference request" do
    store_report(:configuration, :server, :inference)

    render_inline(described_class.new(connection))

    expect(page).to have_test_selector("llm-connection--health-summary",
                                       text: "Full check, including an inference request.")
  end

  it "says when the report was checked without an inference request" do
    store_report(:configuration, :server)

    render_inline(described_class.new(connection))

    expect(page).to have_test_selector("llm-connection--health-summary",
                                       text: "Checked without an inference request")
  end
end
