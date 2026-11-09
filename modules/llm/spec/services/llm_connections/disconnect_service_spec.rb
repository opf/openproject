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
require_module_spec_helper

RSpec.describe LlmConnections::DisconnectService do
  subject(:result) { described_class.new(connection).call }

  let_it_be(:connection, reload: true) { create(:llm_connection, :with_models, api_key: "sk-test") }

  before do
    create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant", model_id: "qwen3.6-27b")
    Setting.llm_features_enabled = true
    allow(Llm::HealthCheckJob).to receive(:toggle_cron_job)
  end

  it "clears the key and disables the features, keeping the endpoint, models and bindings" do
    expect(result).to be_success

    connection.reload
    expect(connection.api_key).to be_blank
    expect(connection.base_url).to eq("https://example.com/v1")
    expect(connection.models.count).to eq(2)
    expect(connection.feature_bindings.pluck(:model_id)).to eq(["qwen3.6-27b"])
    expect(Setting.llm_features_enabled?).to be(false)
  end

  it "toggles the health check cron job" do
    result

    expect(Llm::HealthCheckJob).to have_received(:toggle_cron_job)
  end

  context "when the connection is configured from the environment" do
    before do
      connection.update_columns(env_provisioned_at: Time.current)
      allow(Setting).to receive(:llm_connection).and_return({ "base_url" => "https://example.com/v1" })
    end

    it "fails and changes nothing" do
      expect(result).to be_failure

      expect(connection.reload.api_key).to eq("sk-test")
      expect(Setting.llm_features_enabled?).to be(true)
      expect(Llm::HealthCheckJob).not_to have_received(:toggle_cron_job)
    end
  end

  context "when a seed applies the environment's values after the connection was loaded" do
    before do
      allow(Setting).to receive(:llm_connection).and_return({ "base_url" => "https://example.com/v1" })
      LlmConnection.where(id: connection.id).update_all(api_key: "sk-from-env", env_provisioned_at: Time.current)
    end

    it "fails and keeps the environment's values" do
      expect(result).to be_failure

      connection.reload
      expect(connection.api_key).to eq("sk-from-env")
      expect(connection.env_provisioned_at).to be_present
      expect(Setting.llm_features_enabled?).to be(true)
    end
  end

  context "when the environment configures a connection it has not written yet" do
    before { allow(Setting).to receive(:llm_connection).and_return({ "base_url" => "https://example.com/v1" }) }

    it "disconnects" do
      expect(result).to be_success
      expect(connection.reload.api_key).to be_blank
    end
  end

  context "when the environment no longer configures a connection it once wrote" do
    before { connection.update_columns(env_provisioned_at: Time.current, env_fingerprint: "abc") }

    it "clears the environment's mark with the key" do
      expect(result).to be_success

      connection.reload
      expect(connection.api_key).to be_blank
      expect(connection.env_provisioned_at).to be_nil
      expect(connection.env_fingerprint).to be_nil
    end
  end

  context "when the features switch is set through the environment" do
    before { allow(Settings::Definition[:llm_features_enabled]).to receive_messages(writable?: false, value: true) }

    it "clears the key without writing the switch" do
      allow(Setting).to receive(:llm_features_enabled=)

      expect(result).to be_success
      expect(connection.reload.api_key).to be_blank
      expect(Setting).not_to have_received(:llm_features_enabled=)
    end
  end

  context "when the stored connection no longer passes validation" do
    before { connection.update_column(:base_url, "not a url") }

    it "still disconnects" do
      expect(result).to be_success

      expect(connection.reload.api_key).to be_nil
      expect(Setting.llm_features_enabled?).to be(false)
    end
  end

  context "when writing the setting fails" do
    before { allow(Setting).to receive(:llm_features_enabled=).and_raise(ActiveRecord::StatementInvalid) }

    it "propagates the error and keeps the key" do
      expect { result }.to raise_error(ActiveRecord::StatementInvalid)

      expect(connection.reload.api_key).to eq("sk-test")
      expect(Llm::HealthCheckJob).not_to have_received(:toggle_cron_job)
    end
  end
end
