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

  # The job exists for the startup race with a provisioned LLM sidecar, so a
  # failed fetch has to reach the retry rather than leave the connection without
  # its catalogue.
  it "tries again when the server is not up yet" do
    create(:llm_connection, base_url:)
    mock_llm_models_response(base_url, response_code: 404)

    expect { described_class.perform_now }.to have_enqueued_job(described_class)
  end
end
