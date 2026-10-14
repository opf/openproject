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

RSpec.describe Llm::SyncModelsJob, :llm_server_helpers, :webmock do
  let(:base_url) { "https://example.com/v1" }

  it "refreshes the model list of every stored connection" do
    connection = create(:llm_connection, base_url:)
    request = mock_llm_models_response(base_url)

    described_class.perform_now

    expect(request).to have_been_made.once
    expect(connection.reload.available_model_ids).to contain_exactly("qwen3.6-27b", "bge-m3")
  end

  it "does nothing while no connection is stored" do
    expect { described_class.perform_now }.not_to raise_error
  end

  # The job exists for the startup race with a provisioned LLM sidecar, which
  # either is not listening yet or answers before it has loaded its model.
  {
    "refuses the connection" => { raise_error: Errno::ECONNREFUSED },
    "times out" => { timeout: true },
    "is unavailable" => { response_code: 503 },
    "throttles requests" => { response_code: 429 }
  }.each do |situation, response|
    it "tries again when the server #{situation}" do
      create(:llm_connection, base_url:)
      mock_llm_models_response(base_url, **response)

      expect { described_class.perform_now }.to have_enqueued_job(described_class)
    end
  end

  describe "a server that is up but lists no models yet" do
    {
      "an empty list" => { models: [] },
      "Ollama's list before its first pull" => { body: { object: "list", data: nil }.to_json }
    }.each do |answer, response|
      it "tries again when a connection that has never synced gets #{answer}" do
        create(:llm_connection, base_url:)
        mock_llm_models_response(base_url, **response)

        expect { described_class.perform_now }.to have_enqueued_job(described_class)
      end
    end

    it "keeps trying on the retries, after the empty sync has recorded last_synced_at" do
      connection = create(:llm_connection, base_url:)
      mock_llm_models_response(base_url, models: [])
      described_class.perform_now

      perform_enqueued_jobs(only: described_class)

      expect(connection.reload.last_synced_at).to be_present
      expect(described_class).to have_been_enqueued.exactly(:once)
    end

    it "stops once the server lists a model" do
      create(:llm_connection, base_url:)
      mock_llm_models_response(base_url, models: [])
      described_class.perform_now
      mock_llm_models_response(base_url)

      perform_enqueued_jobs(only: described_class)

      expect(described_class).not_to have_been_enqueued
    end

    it "does not try again when the server lists only a model entered by hand" do
      connection = create(:llm_connection, base_url:)
      create(:llm_model, :manual, llm_connection: connection, external_id: "qwen3.6-27b")
      mock_llm_models_response(base_url, models: [{ id: "qwen3.6-27b" }])

      expect { described_class.perform_now }.not_to have_enqueued_job(described_class)
    end

    it "tries again while the server lists nothing, whatever was entered by hand" do
      connection = create(:llm_connection, base_url:)
      create(:llm_model, :manual, llm_connection: connection, external_id: "qwen3.6-27b")
      mock_llm_models_response(base_url, models: [])

      expect { described_class.perform_now }.to have_enqueued_job(described_class)
    end

    it "tries again when only an earlier sync saw a model" do
      connection = create(:llm_connection, base_url:)
      create(:llm_model, :manual, llm_connection: connection, external_id: "qwen3.6-27b", last_seen_at: 1.hour.ago)
      mock_llm_models_response(base_url, models: [])

      expect { described_class.perform_now }.to have_enqueued_job(described_class)
    end

    it "does not try again for a connection that has synced before" do
      create(:llm_connection, base_url:, last_synced_at: 1.day.ago)
      mock_llm_models_response(base_url, models: [])

      expect { described_class.perform_now }.not_to have_enqueued_job(described_class)
    end
  end

  {
    "has no model list at this URL" => { response_code: 404 },
    "does not implement the model list" => { response_code: 501 },
    "rejects the API key" => { response_code: 401 },
    "answers with something other than a model list" => { body: "<html></html>" }
  }.each do |situation, response|
    it "does not try again when the server #{situation}" do
      create(:llm_connection, base_url:)
      mock_llm_models_response(base_url, **response)

      expect { described_class.perform_now }.not_to have_enqueued_job(described_class)
    end
  end

  it "warns once it gives up on a failure that will not pass on its own" do
    create(:llm_connection, base_url:)
    mock_llm_models_response(base_url, response_code: 404)
    warnings = []
    allow(Rails.logger).to receive(:warn) { |*args, &message| warnings << (message ? message.call : args.first) }

    described_class.perform_now

    expect(warnings).to include(a_string_including("will not be retried", "Server responded with 404"))
  end

  it "tries again when two syncs raced to store the same model" do
    create(:llm_connection, base_url:)
    mock_llm_models_response(base_url)
    allow(LlmConnections::SyncModelsService).to receive(:new).and_wrap_original do |original, connection|
      allow(connection.models).to receive(:find_or_initialize_by).and_raise(ActiveRecord::RecordNotUnique)
      original.call(connection)
    end

    expect { described_class.perform_now }.to have_enqueued_job(described_class)
  end

  it "tries again for a server still starting while another connection is misconfigured" do
    create(:llm_connection, base_url: "https://misconfigured.example/v1")
    create(:llm_connection, base_url:, active: false)
    mock_llm_models_response("https://misconfigured.example/v1", response_code: 404)
    mock_llm_models_response(base_url, timeout: true)

    expect { described_class.perform_now }.to have_enqueued_job(described_class)
  end

  it "refreshes the connections after one whose sync raises" do
    broken = create(:llm_connection, base_url: "https://broken.example/v1")
    healthy = create(:llm_connection, base_url:, active: false)
    request = mock_llm_models_response(base_url)
    allow(LlmConnections::SyncModelsService).to receive(:new).and_call_original
    allow(LlmConnections::SyncModelsService).to receive(:new).with(broken).and_raise("unexpected")

    expect { described_class.perform_now }.not_to raise_error

    expect(request).to have_been_made.once
    expect(healthy.reload.available_model_ids).to contain_exactly("qwen3.6-27b", "bge-m3")
  end
end
