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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Documents::Admin::DocumentTypes::IndexComponent, type: :component do
  subject(:rendered_component) do
    with_controller_class(Documents::Admin::Settings::DocumentTypesController) do
      with_request_url("/admin/settings/document_types") do
        render_inline(described_class.new(enumerations: document_types))
      end
    end
  end

  let(:document_types) { DocumentType.order(:position) }

  context "with document types" do
    let!(:note_type) { create(:document_type, name: "Note", position: 1) }
    let!(:report_type) { create(:document_type, name: "Report", position: 2) }

    let(:draggable_records) { [note_type, report_type] }
    let(:row_test_selector_prefix) { "document-type-row-" }
    let(:move_path_base) { "/admin/settings/document_types" }

    it "renders the add action and the list heading with a count", :aggregate_failures do
      expect(rendered_component).to have_css("[data-test-selector='admin-document-types-subheader']")
      expect(rendered_component).to have_link(I18n.t("documents.button_add_type"))
      expect(rendered_component).to have_css("h3", text: DocumentType.model_name.human(count: :other))
      expect(rendered_component).to have_css(".Counter", text: "2")
    end

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "a reorderable Border Box List"
  end

  context "without document types" do
    it "renders the existing empty result text" do
      expect(rendered_component).to have_text(I18n.t(:no_results_title_text))
    end

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Blank Slate", heading: I18n.t(:no_results_title_text)
  end
end
