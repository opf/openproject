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

RSpec.describe CustomFields::ProjectSpecificValues::SetContract, with_ee: %i[project_specific_list_values] do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }

  subject(:contract) { described_class.new(custom_field, current_user, options: { value: }) }

  context "for a list custom field" do
    let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist) }
    let(:value) { custom_field.custom_options.first }

    it_behaves_like "contract is valid"

    context "with an option of another custom field", :check_errors_i18n do
      let(:value) { create(:list_wp_custom_field).custom_options.first }

      it_behaves_like "contract is invalid", value: :inclusion
    end

    context "with a hierarchy item", with_ee: %i[custom_field_hierarchies project_specific_list_values] do
      let(:value) { create(:hierarchy_item, parent: create(:hierarchy_wp_custom_field).hierarchy_root) }

      it_behaves_like "contract is invalid", value: :inclusion
    end
  end

  context "for a hierarchy custom field", with_ee: %i[custom_field_hierarchies project_specific_list_values] do
    let(:custom_field) { create(:hierarchy_wp_custom_field, :project_specific_allowlist) }
    let(:parent) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }
    let(:value) { create(:hierarchy_item, parent:) }

    it_behaves_like "contract is valid"

    context "with the hierarchy root" do
      let(:value) { custom_field.hierarchy_root }

      it_behaves_like "contract is invalid", value: :inclusion
    end

    context "with an item of another custom field" do
      let(:value) { create(:hierarchy_item, parent: create(:hierarchy_wp_custom_field).hierarchy_root) }

      it_behaves_like "contract is invalid", value: :inclusion
    end
  end
end
