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

RSpec.describe "PDF export template move", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  let(:variant) { type.default_variant }

  current_user { admin }

  def move(template_id, params)
    put move_type_pdf_export_template_path(type_id: type.id, id: template_id),
        params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def ordered_ids
    variant.reload.pdf_export_templates.list.map(&:id)
  end

  def list_type
    "pdf_export_templates"
  end

  it "moves the template below the anchor" do
    move("attributes", { list_type:, list_id: "", prev_id: "artefact" })
    expect(response).to have_http_status(:ok)
    expect(ordered_ids).to eq(%w[contract artefact attributes])
  end

  it "moves the template to the top for a blank prev_id" do
    move("artefact", { list_type:, list_id: "", prev_id: "" })
    expect(response).to have_http_status(:ok)
    expect(ordered_ids).to eq(%w[artefact attributes contract])
  end

  {
    "an unknown anchor" => -> { { list_type:, list_id: "", prev_id: "bogus" } },
    "an omitted prev_id" => -> { { list_type:, list_id: "" } },
    "a wrong list_type" => -> { { list_type: "enumeration", list_id: "", prev_id: "" } },
    "a nonblank list_id" => -> { { list_type:, list_id: "artefact", prev_id: "" } },
    "a collection-valued prev_id" => -> { { list_type:, list_id: "", prev_id: ["artefact"] } },
    "an empty collection prev_id" => -> { { list_type:, list_id: "", prev_id: [""] } },
    "a collection-valued list_id" => -> { { list_type:, list_id: [""], prev_id: "" } }
  }.each do |description, params|
    it "422s without mutation for #{description}" do
      move("attributes", instance_exec(&params))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(ordered_ids).to eq(%w[attributes contract artefact])
    end
  end

  it "renders the invalid-anchor error message on failure" do
    move("attributes", { list_type:, list_id: "", prev_id: "bogus" })
    expect(response.body).to include(I18n.t(:error_invalid_list_move_anchor))
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "does not move an unknown template id" do
    move("bogus", { list_type:, list_id: "", prev_id: "" })
    expect(ordered_ids).to eq(%w[attributes contract artefact])
    expect(response).to have_http_status(:not_found)
  end

  context "when not an admin" do
    current_user { create(:user) }

    it "is forbidden" do
      move("attributes", { list_type:, list_id: "", prev_id: "artefact" })
      expect(ordered_ids).to eq(%w[attributes contract artefact])
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the variant links its PDF export config to its base" do
    let(:linked_variant) { create(:type_variant, type:) }

    before { link_configuration(linked_variant, aspect: TypeVariant::PDF_EXPORT) }

    it "refuses the move with a forbidden turbo-stream flash" do
      put move_type_variant_pdf_export_template_path(type_id: linked_variant.type_id,
                                                     variant_id: linked_variant.id,
                                                     id: "attributes"),
          params: { list_type:, list_id: "", prev_id: "artefact" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include(I18n.t("types.edit.export_configuration.templates.readonly_error"))
    end
  end
end
