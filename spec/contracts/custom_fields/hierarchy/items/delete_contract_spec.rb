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

RSpec.describe CustomFields::Hierarchy::Items::DeleteContract,
               :check_errors_i18n,
               with_ee: %i[custom_field_hierarchies] do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:custom_field) { create(:hierarchy_wp_custom_field) }
  let(:root) { custom_field.hierarchy_root }
  let(:item) { create(:hierarchy_item, parent: root, label: "Luke") }

  subject(:contract) { described_class.new(item, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "for the root" do
    let(:item) { root }

    it_behaves_like "contract is invalid", base: :root_item
  end

  context "for a project item" do
    let(:project) { create(:project) }
    let(:allow_additional_project_values) { true }
    let(:custom_field) { create(:hierarchy_wp_custom_field, allow_additional_project_values:) }
    let(:item) { create(:hierarchy_item, parent: root, label: "Chewie", project:) }

    it_behaves_like "contract is valid for active admins and invalid for regular users"

    context "as a user allowed to manage custom field values in the project" do
      let(:current_user) { build_stubbed(:user) }

      before do
        mock_permissions_for(current_user) do |mock|
          mock.allow_in_project :manage_work_package_custom_field_values, project:
        end
      end

      it_behaves_like "contract is valid"

      context "without the enterprise feature", with_ee: %i[custom_field_hierarchies] do
        it_behaves_like "contract is valid"
      end

      context "when the custom field does not allow additional project values" do
        let(:allow_additional_project_values) { false }

        it_behaves_like "contract is valid"
      end

      context "with a value of another project" do
        let(:item) { create(:hierarchy_item, parent: root, label: "Chewie", project: create(:project)) }

        it_behaves_like "contract user is unauthorized"
      end
    end
  end

  context "as a user allowed to manage custom field values in a project for a global item" do
    let(:current_user) { build_stubbed(:user) }
    let(:custom_field) { create(:hierarchy_wp_custom_field, allow_additional_project_values: true) }

    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_in_project :manage_work_package_custom_field_values, project: create(:project)
      end
    end

    it_behaves_like "contract user is unauthorized"
  end
end
