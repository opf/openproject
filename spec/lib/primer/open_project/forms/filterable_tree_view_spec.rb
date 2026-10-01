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
#
require "spec_helper"

RSpec.describe Primer::OpenProject::Forms::FilterableTreeView, type: :forms do
  include ViewComponent::TestHelpers

  describe "rendering" do
    let(:params) { {} }
    let(:model) { build_stubbed(:comment) }

    def render_form
      render_in_view_context(model, params) do |model, params|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            form.filterable_tree_view(name: :ingredients, label: "Ingredients", **params) do |tree|
              tree.with_leaf(select_variant: :multiple, label: "flour")
              tree.with_leaf(select_variant: :multiple, label: "sugar")
              tree.with_leaf(select_variant: :multiple, label: "eggs")
            end
          end
        end
      end
    end

    subject(:rendered_form) do
      render_form
      page
    end

    it "renders the filterable-tree-view" do
      expect(rendered_form).to have_element :"filterable-tree-view"
    end

    it "renders the fieldset" do
      expect(rendered_form).to have_selector :fieldset, "Ingredients"
    end

    it "renders the label as the fieldset legend" do
      expect(rendered_form).to have_element :legend, class: "FormControl-label", text: "Ingredients"
    end

    it "renders the leafs", :aggregate_failures do
      expect(rendered_form).to have_element(:li, class: "TreeViewItem", role: "none", text: "flour")
      expect(rendered_form).to have_element(:li, class: "TreeViewItem", role: "none", text: "sugar")
      expect(rendered_form).to have_element(:li, class: "TreeViewItem", role: "none", text: "eggs")
    end

    it "wires the tree view up for form submission" do
      expect(rendered_form).to have_element :input, type: "hidden", name: "comment[ingredients][]", visible: :all
    end

    context "when hidden" do
      let(:params) { { hidden: true } }

      it "hides the whole fieldset" do
        expect(rendered_form).to have_selector :fieldset, visible: :hidden
      end
    end
  end
end
