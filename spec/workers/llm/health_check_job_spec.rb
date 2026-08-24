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

require "spec_helper"

RSpec.describe Llm::HealthCheckJob, :llm_server_helpers, :webmock, with_flag: { llm_connection: true } do
  let(:base_url) { "https://example.com/v1" }

  describe "#perform" do
    context "with an enabled connection" do
      let!(:connection) { create(:llm_connection, :with_models, :enabled, base_url:) }

      before { mock_llm_models_response(base_url) }

      it "stores a report" do
        expect { described_class.perform_now }.to change(connection.health_reports, :count).by(1)
      end

      # The whole reason the inference group is gated: an unattended job must not
      # run up a bill on a hosted provider four times a day.
      # Group keys come back from jsonb as strings, so a stored report is
      # queried by string where an in-memory one is queried by symbol.
      it "does not spend a completion" do
        described_class.perform_now

        expect(WebMock).not_to have_requested(:post, "#{base_url}/chat/completions")
        expect(connection.latest_health_report.results.map(&:key)).not_to include("inference")
      end

      it "still reports what the free checks found" do
        described_class.perform_now

        expect(connection.latest_health_report.group("server").result_for("reachable").state).to eq(:success)
      end
    end

    it "does nothing without a connection" do
      expect { described_class.perform_now }.not_to change(HealthReport, :count)
    end

    it "does nothing while the connection is switched off" do
      create(:llm_connection, :with_models, enabled: false, base_url:)

      expect { described_class.perform_now }.not_to change(HealthReport, :count)
    end

    context "with the feature flag off", with_flag: { llm_connection: false } do
      it "does nothing" do
        create(:llm_connection, :with_models, :enabled, base_url:)

        expect { described_class.perform_now }.not_to change(HealthReport, :count)
      end
    end
  end

  describe ".toggle_cron_job" do
    it "enables the cron once a connection is usable" do
      create(:llm_connection, :with_models, :enabled, base_url:)

      described_class.toggle_cron_job

      expect(GoodJob::Setting.cron_key_enabled?(described_class::CRON_JOB_KEY)).to be(true)
    end

    it "disables the cron while there is nothing to check" do
      GoodJob::Setting.cron_key_enable(described_class::CRON_JOB_KEY)

      described_class.toggle_cron_job

      expect(GoodJob::Setting.cron_key_enabled?(described_class::CRON_JOB_KEY)).to be(false)
    end
  end
end
