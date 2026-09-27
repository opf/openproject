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

RSpec.describe Llm::DetectCapabilitiesJob, :llm_server_helpers, :webmock do
  let(:base_url) { "https://example.com/v1" }

  it "probes the likely embedding models of every stored connection" do
    connection = create(:llm_connection, :with_models, base_url:)
    mock_llm_embeddings_response(base_url)

    described_class.perform_now

    expect(connection.capability_verdicts.pluck(:model_id, :source)).to eq([["bge-m3", "probe"]])
  end

  it "does nothing while no connection is stored" do
    expect { described_class.perform_now }.not_to raise_error
  end

  it "probes the connections after one whose detection raises" do
    broken = create(:llm_connection, :with_models, base_url: "https://broken.example/v1")
    healthy = create(:llm_connection, :with_models, base_url:, active: false)
    mock_llm_embeddings_response(base_url)
    allow(LlmConnections::DetectCapabilitiesService).to receive(:new).and_call_original
    allow(LlmConnections::DetectCapabilitiesService).to receive(:new).with(broken)
      .and_raise(ActiveRecord::RecordNotFound, "sk-leaked")
    logged = []
    allow(Rails.logger).to receive(:error) { |&message| logged << message.call }

    expect { described_class.perform_now }.not_to raise_error

    expect(healthy.capability_verdicts.pluck(:model_id)).to eq(["bge-m3"])
    expect(logged).to include("LLM capability detection failed for connection #{broken.id}: ActiveRecord::RecordNotFound")
    expect(logged.join).not_to include("sk-leaked")
  end
end
