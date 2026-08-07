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

RSpec.describe "Project-owned type variants",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:project) { create(:project) }
  shared_let(:stranger) { create(:project) }
  shared_let(:root) { create(:type, name: "Bug") }
  shared_let(:owned_variant) { create(:type, name: "Ours", parent: root, project:) }
  shared_let(:foreign_variant) { create(:type, name: "Theirs", parent: root, project: stranger) }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  before { login_as project_admin }

  describe "#destroy" do
    it "deletes a variant the project owns" do
      delete project_settings_work_packages_types_variant_path(project, owned_variant)

      expect(Type).not_to exist(owned_variant.id)
    end

    context "without the permission" do
      before { login_as create(:user, member_with_permissions: { project => %i[view_project] }) }

      it "refuses and keeps the variant" do
        delete project_settings_work_packages_types_variant_path(project, owned_variant)

        expect(response).not_to have_http_status(:see_other)
        expect(Type).to exist(owned_variant.id)
      end
    end

    context "with the variants feature disabled", with_flag: { type_variants: false } do
      it "is absent" do
        delete project_settings_work_packages_types_variant_path(project, owned_variant)

        expect(response).to have_http_status(:not_found)
        expect(Type).to exist(owned_variant.id)
      end
    end

    # A foreign variant is not merely forbidden: as far as this project is concerned it
    # does not exist, so the two cases stay indistinguishable from outside.
    it "gives 404 for another project's variant" do
      delete project_settings_work_packages_types_variant_path(project, foreign_variant)

      expect(response).to have_http_status(:not_found)
      expect(Type).to exist(foreign_variant.id)
    end

    it "gives 404 for a global variant" do
      global_variant = create(:type, name: "Global", parent: root)

      delete project_settings_work_packages_types_variant_path(project, global_variant)

      expect(response).to have_http_status(:not_found)
      expect(Type).to exist(global_variant.id)
    end
  end
end
