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
require "contracts/shared/model_contract_shared_context"

RSpec.describe CustomOptions::CreateContract do
  include_context "ModelContract shared context"

  current_user { build_stubbed(:admin) }

  let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Berlin], allow_additional_project_values: true) }
  let(:project) { create(:project) }
  let(:option_project) { nil }
  let(:option_value) { "Hamburg" }
  let(:custom_option) { CustomOption.new(custom_field:, value: option_value, position: 2, project: option_project) }

  subject(:contract) { described_class.new(custom_option, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "without a custom field" do
    let(:custom_option) { CustomOption.new(value: option_value) }

    it_behaves_like "contract is invalid", custom_field: :blank
  end

  context "with a project" do
    let(:option_project) { project }

    it_behaves_like "contract is valid"

    context "when the custom field does not allow additional project values" do
      let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Berlin], allow_additional_project_values: false) }

      it_behaves_like "contract is invalid", project_id: :additional_values_not_allowed
    end
  end
end
