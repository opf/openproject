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

require "rails_helper"

RSpec.describe AttributeHelpTexts::TableComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) do
    render_component(rows: attribute_help_texts)
  end

  shared_examples_for "rendering Border Box Grid headings" do
    include_examples "rendering Border Box Grid heading", text: "Attribute"
    include_examples "rendering Border Box Grid heading", text: "Help text"
    include_examples "rendering Border Box Grid mobile heading", text: "Attribute help texts"
  end

  context "with no attribute help texts" do
    let(:attribute_help_texts) { [] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Blank Slate", heading: "Nothing to display"
  end

  context "with attribute help texts" do
    let(:status_help_text) { create(:work_package_help_text, attribute_name: "status") }
    let(:project_help_text) { create(:work_package_help_text, attribute_name: "project") }
    let(:attribute_help_texts) { [status_help_text, project_help_text] }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 2

    it "renders a link to edit each attribute" do
      expect(rendered_component).to have_link(
        status_help_text.attribute_field_name,
        href: edit_attribute_help_text_path(status_help_text)
      )
      expect(rendered_component).to have_link(
        project_help_text.attribute_field_name,
        href: edit_attribute_help_text_path(project_help_text)
      )
    end

    it "renders a link to preview the help text" do
      expect(rendered_component).to have_link(href: show_dialog_attribute_help_text_path(status_help_text))
    end

    it "renders a delete button for each row" do
      expect(rendered_component).to have_link(href: attribute_help_text_path(status_help_text))
      expect(rendered_component).to have_link(href: attribute_help_text_path(project_help_text))
    end
  end
end
