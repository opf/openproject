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

# Include OpenProject support/*.rb files
require "spec_helper"
require_module_spec_helper
require "contracts/shared/model_contract_shared_context"

# Purpose: Common testing logic shared between create and update specs.
RSpec.shared_examples_for "ProjectStorages contract" do
  include_context "ModelContract shared context"

  let(:current_user) { create(:user) }
  let(:role) { create(:project_role, permissions: %i[manage_files_in_project]) }
  # Create a project managed by current user and with Storages enabled.
  let(:project) do
    create(:project,
           members: { current_user => role },
           enabled_module_names: %i[storages])
  end
  let(:storage) { create(:nextcloud_storage, name: "Storage 1") }
  let(:storage_creator) { current_user }

  # This is not 100% precise, as the required permission is not :admin
  # but :manage_files_in_project, but let's still include this.
  it_behaves_like "contract is valid for active admins and invalid for regular users"

  describe "validations" do
    context "when authorized, with permissions and all attributes are valid" do
      it_behaves_like "contract is valid"
    end

    context "when project is invalid" do
      context "as it is nil" do
        let(:project) { nil }

        it_behaves_like "contract is invalid"
      end
    end

    context "when storage is invalid" do
      context "as it is nil" do
        let(:storage) { nil }

        it_behaves_like "contract is invalid"
      end
    end

    context "when not the necessary permissions" do
      let(:current_user) { build_stubbed(:user) }

      it_behaves_like "contract user is unauthorized"
    end
  end

  include_examples "contract reuses the model errors"
end
