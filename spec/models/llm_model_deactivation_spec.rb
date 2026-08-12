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

RSpec.describe LlmModel, "deactivation", :llm_server_helpers, :webmock,
               with_flag: { llm_connection: true } do
  let(:base_url) { "https://example.com/v1" }
  let!(:connection) { create(:llm_connection, :with_models, :enabled, base_url:) }
  let(:model) { connection.models.find_by(external_id: "qwen3.6-27b") }

  before { model.update!(deactivated_at: Time.current) }

  it "hides the model from the pickers" do
    expect(connection.selectable_model_ids).not_to include("qwen3.6-27b")
    expect(connection.selectable_model_ids).to include("bge-m3")
  end

  # The decision that makes the toggle safe: curation, not enforcement. A row an
  # administrator switches off must never silently break a running feature.
  it "keeps a feature already bound to it working" do
    connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "qwen3.6-27b")

    expect(connection.available_model_ids).to include("qwen3.6-27b")
    expect(Llm::Runtime.for(:description_assistant)).to be_ready
  end

  it "still offers it to the feature that is bound to it" do
    connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "qwen3.6-27b")

    options = LlmConnections::SelectableModelsQuery
                .new(connection, OpenProject::Llm::Features[:description_assistant])
                .call

    expect(options.map(&:model_id)).to include("qwen3.6-27b")
  end

  # The reason deactivated_at exists rather than reusing active: the sync writes
  # active on every refresh, so an administrator's choice stored there would be
  # undone by the next "Refresh models".
  it "survives a catalogue sync that still reports the model" do
    mock_llm_models_response(base_url)

    LlmConnections::SyncModelsService.new(connection).call

    expect(model.reload).to be_deactivated
    expect(model).to be_active
    expect(model).not_to be_selectable
  end

  it "is distinct from a model the server withdrew" do
    withdrawn = create(:llm_model, :withdrawn, llm_connection: connection, external_id: "gone")

    expect(withdrawn).to be_withdrawn
    expect(model).not_to be_withdrawn
  end
end
