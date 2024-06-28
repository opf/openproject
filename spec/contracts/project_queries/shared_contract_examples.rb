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

RSpec.shared_examples_for "project queries contract" do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:query_name) { "Query name" }
  let(:query_user) { current_user }
  let(:query_selects) { %i[name project_status] }

  describe "validation" do
    it_behaves_like "contract is valid"

    context "if the name is nil" do
      let(:query_name) { nil }

      it_behaves_like "contract is invalid", name: :blank
    end

    context "if the name is too long" do
      let(:query_name) { "A" * 256 }

      it_behaves_like "contract is invalid", name: :too_long
    end

    context "if the user is not the current user and does not have the permission" do
      let(:query_user) { build_stubbed(:user) }

      it_behaves_like "contract is invalid", base: :can_only_be_modified_by_owner
    end

    context "if the user is not the current user but has the permission" do
      let(:query_user) { build_stubbed(:user) }

      before do
        mock_permissions_for(current_user) do |mock|
          mock.allow_in_project_query :edit_project_query, project_query: query
        end
      end

      it_behaves_like "contract is valid"
    end

    context "if the list is public and the editing user has the global permission" do
      let(:query_user) { build_stubbed(:user) }

      before do
        query.change_by_system do
          query.public = true
        end

        mock_permissions_for(current_user) do |mock|
          mock.allow_globally :manage_public_project_queries
        end
      end

      it_behaves_like "contract is valid"
    end

    context "if the list is public and the editing user does not have the global permission" do
      let(:query_user) { build_stubbed(:user) }

      before do
        query.change_by_system do
          query.public = true
        end

        mock_permissions_for(current_user, &:forbid_everything)
      end

      it_behaves_like "contract is invalid", base: :need_permission_to_modify_public_query
    end

    context "if the list is public and the editing user does not have the global permission but has edit rights on the item" do
      let(:query_user) { build_stubbed(:user) }

      before do
        query.change_by_system do
          query.public = true
        end

        mock_permissions_for(current_user) do |mock|
          mock.allow_in_project_query :edit_project_query, project_query: query
        end
      end

      it_behaves_like "contract is valid"
    end

    context "if the list is public and the editing user does not have the permission, even if they are the owner" do
      let(:query_user) { current_user }

      before do
        query.change_by_system do
          query.public = true
        end

        mock_permissions_for(current_user, &:forbid_everything)
      end

      it_behaves_like "contract is invalid", base: :need_permission_to_modify_public_query
    end

    context "if the user and the current user is anonymous" do
      let(:current_user) { build_stubbed(:anonymous) }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "if the selects do not include the name column" do
      let(:query_selects) { %i[project_status] }

      it_behaves_like "contract is invalid", selects: :name_not_included
    end

    context "if the selects include a non existing one" do
      let(:query_selects) { %i[project_status name foo_bar] }

      it_behaves_like "contract is invalid", selects: :nonexistent
    end
  end
end
