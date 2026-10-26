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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe CustomFields::ProjectSpecificValues::BaseContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:custom_field) { build(:list_wp_custom_field, :project_specific_allowlist) }

  subject(:contract) { described_class.new(custom_field, current_user) }

  context "with an enterprise plan including project-specific values", with_ee: %i[project_specific_list_values] do
    it_behaves_like "contract is valid for active admins and invalid for regular users"

    context "without project-specific restrictions enabled", :check_errors_i18n do
      let(:custom_field) { build(:list_wp_custom_field) }

      it_behaves_like "contract is invalid", project_specific_value_restriction: :blank
    end
  end

  context "with an enterprise plan not including project-specific values", :check_errors_i18n do
    it_behaves_like "contract is invalid", base: :error_enterprise_only
  end
end
