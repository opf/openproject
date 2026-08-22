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

RSpec.describe Llm::Validators::ConnectionValidator, :llm_server_helpers, :webmock,
               with_flag: { llm_connection: true } do
  subject(:report) { described_class.new(connection).call }

  let(:base_url) { "https://example.com/v1" }
  let(:connection) { create(:llm_connection, :with_models, :enabled, base_url:) }

  def result_for(group, key)
    report.group(group)&.result_for(key)
  end

  context "with a healthy connection" do
    before do
      mock_llm_models_response(base_url)
      connection.update!(default_chat_model_id: "qwen3.6-27b")
    end

    it "passes the configuration and server groups" do
      expect(result_for(:configuration, :base_url_present).state).to eq(:success)
      expect(result_for(:server, :reachable).state).to eq(:success)
      expect(result_for(:server, :credentials_accepted).state).to eq(:success)
    end

    # The billed request only runs when an administrator asks for it.
    it "skips inference unless a deep check was asked for" do
      expect(report.group(:inference)).to be_nil
      expect(WebMock).not_to have_requested(:post, "#{base_url}/chat/completions")
    end

    context "when a deep check is asked for" do
      before do
        connection.deep_health_check = true
        mock_llm_chat_response(base_url, content: "pong")
      end

      it "sends a completion and reports the round trip" do
        expect(result_for(:inference, :chat_round_trip).state).to eq(:success)
        expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions").once
      end
    end
  end

  context "when the server publishes no model list" do
    before { mock_llm_models_response(base_url, response_code: 404) }

    # The case that motivated manual model entry: a gateway exposing only chat.
    it "is still reachable, and says the key could not be verified" do
      expect(result_for(:server, :reachable).state).to eq(:success)
      expect(result_for(:server, :credentials_accepted).state).to eq(:warning)
      expect(result_for(:server, :credentials_accepted).code).to eq(:no_models_endpoint)
    end

    it "can still prove the connection works through inference" do
      connection.deep_health_check = true
      connection.update!(default_chat_model_id: "qwen3.6-27b")
      mock_llm_chat_response(base_url)

      expect(result_for(:inference, :chat_round_trip).state).to eq(:success)
    end
  end

  context "when the key is rejected" do
    before { mock_llm_models_response(base_url, response_code: 401) }

    it "separates reachability from authentication" do
      expect(result_for(:server, :reachable).state).to eq(:success)
      expect(result_for(:server, :credentials_accepted).state).to eq(:failure)
      expect(report).to be_unhealthy
    end
  end

  context "when the server cannot be reached" do
    before { mock_llm_models_response(base_url, timeout: true) }

    it "fails reachability and skips the credential check" do
      expect(result_for(:server, :reachable).state).to eq(:failure)
      expect(result_for(:server, :credentials_accepted).state).to eq(:skipped)
    end
  end

  context "without a base URL" do
    let(:connection) { create(:llm_connection, :enabled).tap { |c| c.update_column(:base_url, "") } }

    it "fails and does not ask the server anything" do
      expect(result_for(:configuration, :base_url_present).state).to eq(:failure)
      expect(report.group(:server)).to be_nil
      expect(WebMock).not_to have_requested(:get, "#{base_url}/models")
    end
  end

  describe "the features group" do
    before { mock_llm_models_response(base_url) }

    it "warns about features with no model chosen" do
      result = result_for(:features, :bindings_resolvable)

      expect(result.state).to eq(:warning)
      expect(result.code).to eq(:features_unbound)
    end

    it "fails when a binding points at a model the server no longer offers" do
      connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "vanished")

      result = result_for(:features, :bindings_resolvable)

      expect(result.state).to eq(:failure)
      expect(result.code).to eq(:features_model_missing)
    end
  end

  # HealthReports::ResultComponent resolves a check's label from its key and its
  # explanation from its code, so a key with no translation renders as
  # "translation missing" rather than failing anywhere a spec would notice.
  describe "translations" do
    let(:scenarios) do
      [
        -> { mock_llm_models_response(base_url) },
        -> { mock_llm_models_response(base_url, response_code: 401) },
        -> { mock_llm_models_response(base_url, response_code: 404) },
        -> { mock_llm_models_response(base_url, timeout: true) }
      ]
    end

    it "exist for every check and every code the validator can emit" do
      # A dangling binding, so the features group emits its failure codes too.
      connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "vanished")

      scenarios.each do |setup|
        WebMock.reset!
        setup.call

        described_class.new(connection).call.results.each do |group|
          expect(I18n.t("#{group.key}.header", scope: "llm.health_checks", raise: true)).to be_present

          group.results.each do |result|
            expect(I18n.t("#{group.key}.#{result.key}", scope: "llm.health_checks", raise: true)).to be_present
            next if result.code.nil?

            context_vars = result.context&.symbolize_keys || {}
            expect(I18n.t("errors.#{result.code}", scope: "llm.health_checks", raise: true, **context_vars))
              .to be_present
          end
        end
      end
    end
  end
end
