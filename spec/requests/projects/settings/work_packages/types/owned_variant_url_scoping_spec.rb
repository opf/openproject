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

# Every screen a project reaches is rendered by administration's own components, which name their
# routes without knowing which of the two addresses they are on. The project rides on the request:
# it is a segment of the route being generated, so it is filled in from the path already being
# served. Two things break that, and neither shows up as a failed status code — a route with no
# such segment, which takes the project as a query parameter and points at a different screen, and
# a route on the type collection, which has nothing in the request to match and so falls back to
# administration's address.
RSpec.describe "The URLs a project's variant screens generate",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
  shared_let(:actor) { create(:user, member_with_permissions: { project => %i[manage_project_variants] }) }

  before { login_as actor }

  def rendered_urls
    response.body.scan(/(?:action|href|src|data-drop-url|drop-url)="([^"]+)"/)
            .flatten.uniq.reject { |url| url.include?("/api/") }
  end

  def expect_every_url_scoped_to_the_project(screen)
    expect(response).to have_http_status(:ok)

    variant_urls = rendered_urls.grep(%r{/types/})
    expect(variant_urls).not_to be_empty, "expected #{screen} to link somewhere"

    administration = variant_urls.reject { |url| url.include?("in-project/#{project.identifier}") }
    expect(administration).to be_empty,
                              "#{screen} points at administration:\n  #{administration.join("\n  ")}"

    dangling = rendered_urls.grep(/[?&]in_project_id=/)
    expect(dangling).to be_empty,
                        "#{screen} carries the project as a query parameter:\n  #{dangling.join("\n  ")}"
  end

  {
    "details" => :edit_type_details_path,
    "defaults" => :edit_type_defaults_path,
    "form configuration" => :edit_type_form_configuration_path,
    "project attributes" => :edit_type_project_attributes_path,
    "export configuration" => :edit_type_pdf_export_template_index_path,
    "workflow" => :edit_type_workflow_path
  }.each do |name, helper|
    it "keeps the project in every URL on the #{name} tab" do
      get send(helper, in_project_id: project, type_id: type.id, variant_id: ours.id)

      expect_every_url_scoped_to_the_project("the #{name} tab")
    end
  end

  # The first step posts to the type collection, where no segment of the request matches.
  it "keeps the project in every URL on the wizard's first step" do
    get new_creation_wizard_types_path(in_project_id: project, type_id: type.id)

    expect_every_url_scoped_to_the_project("the wizard's first step")
  end

  it "keeps the project in every URL on a later wizard step" do
    get type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id,
                                  step: "defaults")

    expect_every_url_scoped_to_the_project("the wizard's defaults step")
  end
end
