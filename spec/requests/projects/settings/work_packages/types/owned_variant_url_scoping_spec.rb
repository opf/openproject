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

# Every screen a project reaches is rendered by the same components as administration's, which pick
# the route family from the scope they are rendered in. One that picks administration's instead
# still renders fine, and only leads the project member to a screen they cannot open.
RSpec.describe "The URLs a project's variant screens generate",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
  shared_let(:actor) { create(:user, member_with_permissions: { project => %i[manage_project_variants] }) }

  let(:ours_in_project) { { project_id: project, type_id: type.id, variant_id: ours.id } }

  before { login_as actor }

  def rendered_urls
    response.body.scan(/(?:action|href|src|data-drop-url|drop-url)="([^"]+)"/)
            .flatten.uniq.reject { |url| url.include?("/api/") }
  end

  def expect_every_url_scoped_to_the_project(screen)
    expect(response).to have_http_status(:ok)

    variant_urls = rendered_urls.grep(%r{/types/})
    expect(variant_urls).not_to be_empty, "expected #{screen} to link somewhere"

    administration = variant_urls.reject { |url| URI(url).path.start_with?("/projects/#{project.identifier}/") }
    expect(administration).to be_empty,
                              "#{screen} points at administration:\n  #{administration.join("\n  ")}"
  end

  {
    "configuration overview" => :project_type_variant_settings_path,
    "details" => :edit_project_type_variant_details_path,
    "defaults" => :edit_project_type_variant_defaults_path,
    "form configuration" => :edit_project_type_variant_form_configuration_path,
    "project attributes" => :edit_project_type_variant_project_attributes_path,
    "export configuration" => :edit_project_type_variant_pdf_export_template_index_path,
    "workflow" => :edit_project_type_variant_workflow_path
  }.each do |name, helper|
    it "keeps the project in every URL on the #{name} tab" do
      get send(helper, **ours_in_project)

      expect_every_url_scoped_to_the_project("the #{name} tab")
    end
  end

  it "keeps the project in every URL on the wizard's first step" do
    get new_creation_wizard_project_type_variants_path(project_id: project, type_id: type.id)

    expect_every_url_scoped_to_the_project("the wizard's first step")
  end

  it "keeps the project in every URL on a later wizard step" do
    get project_type_variant_creation_wizard_path(**ours_in_project, step: "defaults")

    expect_every_url_scoped_to_the_project("the wizard's defaults step")
  end
end
