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

RSpec.describe OpenProject::Common::InplaceEditFields::HierarchyListComponent,
               type: :component, with_ee: [:custom_field_hierarchies] do
  include ViewComponent::TestHelpers

  describe ".open_in_dialog?" do
    it "returns true so that the field always opens in a dialog" do
      expect(described_class.open_in_dialog?).to be(true)
    end
  end

  context "with a single-value hierarchy custom field" do
    let(:project) { create(:project) }
    let(:custom_field) { create(:project_custom_field, :hierarchy) }
    let(:attribute) { custom_field.attribute_name.to_sym }
    let!(:item) { create(:hierarchy_item, label: "Alpha", parent: custom_field.hierarchy_root) }

    def render_component
      component_class = described_class
      cf_attribute = attribute
      cf_label = custom_field.name
      render_in_view_context(project) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            render component_class.new(form:, model:, attribute: cf_attribute, label: cf_label)
          end
        end
      end
    end

    it "renders a filterable-tree-view element" do
      render_component

      expect(rendered_content).to have_css("filterable-tree-view")
    end

    it "renders a hidden sentinel field to allow clearing the selection" do
      render_component

      expect(rendered_content).to have_field("project[custom_field_values][]", type: :hidden, with: "")
    end

    it "renders item labels inside the tree" do
      render_component

      expect(rendered_content).to have_text("Alpha")
    end

    it "renders items with single-select checkmarks" do
      render_component

      expect(rendered_content).to have_css(".TreeViewItem-singleSelectCheckmark")
    end
  end

  context "with a multi-value hierarchy custom field" do
    let(:project) { create(:project) }
    let(:custom_field) { create(:project_custom_field, :multi_hierarchy) }
    let(:attribute) { custom_field.attribute_name.to_sym }
    let!(:item) { create(:hierarchy_item, label: "Beta", parent: custom_field.hierarchy_root) }

    it "renders items with multi-select checkboxes" do
      component_class = described_class
      cf_attribute = attribute
      cf_label = custom_field.name
      render_in_view_context(project) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            render component_class.new(form:, model:, attribute: cf_attribute, label: cf_label)
          end
        end
      end

      expect(rendered_content).to have_css(".FormControl-checkbox")
    end
  end

  context "with a pre-selected item" do
    let(:user) { create(:admin) }
    let(:project) { create(:project) }
    let(:custom_field) { create(:project_custom_field, :hierarchy, projects: [project]) }
    let(:attribute) { custom_field.attribute_name.to_sym }
    let!(:item) { create(:hierarchy_item, label: "Gamma", parent: custom_field.hierarchy_root) }

    before do
      allow(User).to receive(:current).and_return(user)
      create(:custom_value, :skip_validations, customized: project, custom_field:, value: item.id.to_s)
    end

    it "marks the currently selected item as checked" do
      component_class = described_class
      cf_attribute = attribute
      cf_label = custom_field.name
      render_in_view_context(Project.find(project.id)) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            render component_class.new(form:, model:, attribute: cf_attribute, label: cf_label)
          end
        end
      end

      expect(rendered_content).to have_css("[aria-checked='true']", text: "Gamma")
    end
  end
end
