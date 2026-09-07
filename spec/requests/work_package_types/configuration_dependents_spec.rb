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

RSpec.describe "Work package type configuration dependents",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:borrowing_type) { create(:type, name: "Feature") }

  let(:aspect) { TypeVariant::PDF_EXPORT }

  before { login_as admin }

  describe "the dependents box on a configuration tab" do
    it "reports no dependents while nothing borrows the aspect" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No dependent types")
    end

    it "counts the dependents once another variant borrows the aspect" do
      link_configuration(borrowing_type, source: type, aspect:)

      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("1 dependent type")
      expect(response.body).to include("View dependent types")
    end

    it "counts a variant borrowing through another one in the same total" do
      link_configuration(borrowing_type, source: type, aspect:)
      link_configuration(create(:type, name: "Bug"), source: borrowing_type, aspect:)

      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("2 dependent types")
    end
  end

  describe "the dialog" do
    before { link_configuration(borrowing_type, source: type, aspect:) }

    it "lists every dependent with a link to its own configuration" do
      get type_configuration_dependents_dialog_path(type_id: type.id, aspect:), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Feature")
      expect(response.body).to include(
        edit_type_pdf_export_template_index_path(type_id: borrowing_type.id,
                                                 variant_id: borrowing_type.default_variant.id)
      )
    end

    it "lists a variant borrowing through another, naming the variant it comes through" do
      indirect_variant = create(:type_variant, type: create(:type, name: "Bug"), variant_name: "iOS")
      link_configuration(indirect_variant, source: borrowing_type, aspect:)

      get type_configuration_dependents_dialog_path(type_id: type.id, aspect:), as: :turbo_stream

      expect(response.body).to include("Direct dependents")
      expect(response.body).to include("Dependents through other types")
      expect(response.body).to include("Variant of <b>Bug</b>, inheriting via")
      expect(response.body).to include(
        edit_type_pdf_export_template_index_path(type_id: indirect_variant.type_id,
                                                 variant_id: indirect_variant.id)
      )
    end

    it "renders 404 for an unknown aspect" do
      get type_configuration_dependents_dialog_path(type_id: type.id, aspect: "nonsense"), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    context "when the variants feature is disabled", with_flag: { type_variants: false } do
      it "blocks the dialog" do
        get type_configuration_dependents_dialog_path(type_id: type.id, aspect:), as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not an admin" do
      shared_let(:user) { create(:user) }

      it "blocks the dialog" do
        login_as user

        get type_configuration_dependents_dialog_path(type_id: type.id, aspect:), as: :turbo_stream

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
