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
require "contracts/shared/model_contract_shared_context"

RSpec.describe LlmModels::UpdateContract, :check_errors_i18n do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:connection) { create(:llm_connection) }
  let(:llm_model) { create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed") }
  let(:contract) { described_class.new(llm_model, current_user) }

  before { llm_model.display_name = "Hand typed" }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "when renaming a model entered by hand" do
    before { llm_model.external_id = "hand-typed:v2" }

    include_examples "contract is valid"
  end

  context "when renaming a discovered model" do
    let(:llm_model) { create(:llm_model, llm_connection: connection, external_id: "server-named") }

    before { llm_model.external_id = "renamed" }

    include_examples "contract is invalid", external_id: :error_readonly
  end

  context "when setting the context window" do
    before do
      llm_model.update_columns(raw_metadata: { "max_model_len" => 8192 })
      llm_model.admin_context_window = "32768"
    end

    include_examples "contract is valid"
  end

  context "when writing other metadata" do
    before { llm_model.raw_metadata = llm_model.raw_metadata.merge("max_model_len" => 1) }

    include_examples "contract is invalid", raw_metadata: :error_readonly
  end

  context "when asserting a state that is not one" do
    before { llm_model.capability_vision = "maybe" }

    include_examples "contract is invalid", capability_vision: :inclusion
  end

  context "when the environment names the model as a default" do
    before do
      connection.update_columns(default_chat_model_id: llm_model.id, env_provisioned_at: Time.current)
      allow(Setting).to receive(:llm_connection).and_return({ "default_chat_model" => "hand-typed" })
    end

    include_examples "contract is valid"

    context "and it is renamed" do
      before { llm_model.external_id = "renamed" }

      include_examples "contract is invalid", base: :configured_from_env
    end
  end
end
