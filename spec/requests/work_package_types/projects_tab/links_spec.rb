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

RSpec.describe "Removing a work package type from several projects", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }

  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [type]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:unrelated) { create(:project, name: "Unrelated", types: []) }

  before { login_as admin }

  def uses_type?(project) = project.reload.project_types.exists?(type_id: type.id)

  def remove_from(*projects)
    delete type_projects_link_path(type_id: type.id),
           params: { project_ids: projects.map(&:id) },
           as: :turbo_stream
  end

  describe "DELETE link" do
    it "removes the type from every given project" do
      remove_from(bookshop, foundry)

      expect(response).to have_http_status(:ok)
      expect(uses_type?(bookshop)).to be(false)
      expect(uses_type?(foundry)).to be(false)
    end

    it "closes the confirmation and repaints the project list" do
      remove_from(bookshop, foundry)

      expect(response.body).to include("closeDialog").and include("type-projects-bulk-remove-dialog")
      expect(response.body).to include(%(target="#{WorkPackageTypes::ProjectsTab::TableComponent.wrapper_key}"))
    end

    context "when one project still has work packages of the type" do
      before { create(:work_package, project: foundry, type:) }

      it "removes the type from the others" do
        remove_from(bookshop, foundry)

        expect(uses_type?(bookshop)).to be(false)
      end

      it "keeps the type in the blocked project and names it" do
        remove_from(bookshop, foundry)

        expect(uses_type?(foundry)).to be(true)
        expect(response.body).to include("Foundry")
      end
    end

    it "ignores a project that does not use the type" do
      create(:work_package, project: unrelated, type:)

      expect { remove_from(bookshop, unrelated) }
        .not_to change { unrelated.reload.project_types.pluck(:id) }

      expect(uses_type?(bookshop)).to be(false)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Unrelated")
    end
  end

  describe "GET link/deletion/new" do
    it "asks to confirm the removal, listing the projects with their variants" do
      get new_type_projects_link_deletion_path(type_id: type.id),
          params: { project_ids: [bookshop.id, foundry.id] },
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Remove type &#39;Bug&#39; from these projects?")
        .and include("Bookshop").and include("Foundry").and include("Hardware")
    end
  end

  context "without admin access" do
    before { login_as create(:user) }

    it "refuses the removal" do
      remove_from(bookshop)

      expect(response).to have_http_status(:forbidden)
      expect(uses_type?(bookshop)).to be(true)
    end

    it "refuses the confirmation" do
      get new_type_projects_link_deletion_path(type_id: type.id), params: { project_ids: [bookshop.id] }, as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end
  end
end
