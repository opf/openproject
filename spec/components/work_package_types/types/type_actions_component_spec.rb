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

RSpec.describe WorkPackageTypes::Types::TypeActionsComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:root_type) { create(:type, name: "Bug") }
  shared_let(:sibling_type) { create(:type, name: "Feature") }

  current_user { create(:admin) }

  describe "menu items" do
    context "for a type" do
      subject(:rendered_component) { render_inline(described_class.new(type: root_type)) }

      it "offers configure, make default, add variant, duplicate, move and delete", :aggregate_failures do
        expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_configure) do |item|
          expect(item[:href]).to eq type_settings_path(type_id: root_type.id)
        end
        expect(rendered_component).to have_selector :menuitem, text: I18n.t("types.index.make_default")
        expect(rendered_component).to have_selector :menuitem, text: I18n.t("types.index.add_variant_action")
        expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_duplicate)
        expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_move)
        expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_delete)
      end
    end

    context "when the type is the current default" do
      subject(:rendered_component) { render_inline(described_class.new(type: root_type)) }

      before { root_type.default_variant.update!(enabled_in_new_projects: true) }

      it "offers removing the default instead of setting it", :aggregate_failures do
        expect(rendered_component).to have_selector :menuitem, text: I18n.t("types.index.remove_default")
        expect(rendered_component).to have_no_selector :menuitem, text: I18n.t("types.index.make_default")
      end
    end

    context "when there is only one type" do
      subject(:rendered_component) { render_inline(described_class.new(type: root_type)) }

      before { allow(root_type).to receive_messages(first?: true, last?: true) }

      it "omits move" do
        expect(rendered_component).to have_no_selector :menuitem, text: I18n.t(:button_move)
      end
    end
  end

  describe "paginated moves" do
    let!(:types) { %w[A B C D E].map { |name| create(:type, name:) } }
    let(:ordered) { Type.order(:position) }
    let(:page_two) { ordered.page(2).per_page(2).to_a }
    let(:page_args) { { page: 2, per_page: 2 } }

    def render_for(type, **args)
      render_inline(described_class.new(type:, **args))
    end

    def expect_directions(rendered, present: [], absent: [])
      aggregate_failures do
        present.each { |label| expect(rendered).to have_selector(:menuitem, text: I18n.t(label)) }
        absent.each { |label| expect(rendered).to have_no_selector(:menuitem, text: I18n.t(label)) }
      end
    end

    it "keeps all directions for a page's first type and submits with page context" do
      first_on_page = page_two.first
      expect(first_on_page).not_to eq(ordered.first)

      rendered = render_for(first_on_page, page_args:)

      expect_directions(rendered, present: %i[label_sort_highest label_sort_higher label_sort_lower label_sort_lowest])
      expect(rendered).to have_element(:form, action: move_type_path(first_on_page, **page_args), count: 4)
      expect(rendered).to have_field("_method", type: :hidden, with: "put", count: 4)
    end

    it "keeps downward moves for a page's last type" do
      last_on_page = page_two.last
      expect(last_on_page).not_to eq(ordered.last)

      rendered = render_for(last_on_page, page_args:)

      expect_directions(rendered, present: %i[label_sort_lower label_sort_lowest])
    end

    it "omits upward directions at the global start" do
      expect_directions(render_for(ordered.first),
                        present: %i[label_sort_lower label_sort_lowest],
                        absent: %i[label_sort_highest label_sort_higher])
    end

    it "omits downward directions at the global end" do
      expect_directions(render_for(ordered.last),
                        present: %i[label_sort_highest label_sort_higher],
                        absent: %i[label_sort_lower label_sort_lowest])
    end
  end
end
