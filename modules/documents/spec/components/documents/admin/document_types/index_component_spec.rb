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

RSpec.describe Documents::Admin::DocumentTypes::IndexComponent, type: :component do
  let!(:first_type) { create(:document_type, name: "Note") }
  let!(:second_type) { create(:document_type, name: "Report") }

  subject(:rendered_component) do
    with_request_url("/admin/settings/document_types") do
      render_inline(described_class.new(enumerations: DocumentType.reorder(:position)))
    end
  end

  it_behaves_like "a sortable-lists root",
                  wrapper_id: "documents-admin-document-types-index-component",
                  move_url_template: "/admin/settings/document_types/{id}/move"
  it_behaves_like "a sortable-lists list",
                  list_type: "document_type",
                  name: DocumentType.model_name.human(count: :other)
  it_behaves_like "a Border Box sortable list", row_count: 2
  it_behaves_like "sortable-lists items", list_type: "document_type" do
    let(:sortable_records) { [first_type, second_type] }
  end
  it_behaves_like "no legacy drag-and-drop wiring"

  it "keeps the two-column grid" do
    expect(rendered_component).to have_css(".op-documents-types-list--header", visible: :all)
    expect(rendered_component).to have_css(".op-documents-types-list--item", count: 2, visible: :all)
  end
end
