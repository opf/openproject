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

RSpec.describe LlmModels::CreateContract, :check_errors_i18n do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:connection) { create(:llm_connection) }
  let(:llm_model) do
    LlmModel.new.extend(OpenProject::ChangedBySystem).tap do |model|
      model.change_by_system { model.manual = true }
      model.assign_attributes(llm_connection: connection, external_id: "hand-typed", admin_context_window: "8192")
    end
  end
  let(:contract) { described_class.new(llm_model, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "without an identifier" do
    before { llm_model.external_id = "" }

    include_examples "contract is invalid", external_id: :blank
  end

  context "when the caller sets the origin itself" do
    let(:llm_model) { LlmModel.new(llm_connection: connection, external_id: "hand-typed", manual: true) }

    include_examples "contract is invalid", manual: :error_readonly
  end
end
