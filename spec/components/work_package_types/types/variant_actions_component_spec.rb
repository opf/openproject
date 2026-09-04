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

RSpec.describe WorkPackageTypes::Types::VariantActionsComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:root_type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type: root_type, variant_name: "Hardware") }

  current_user { create(:admin) }

  subject(:rendered_component) { render_inline(described_class.new(variant:)) }

  describe "menu items" do
    it "offers configure, make default and delete", :aggregate_failures do
      expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_configure) do |item|
        expect(item[:href]).to eq edit_type_details_path(type_id: root_type.id, variant_id: variant.id)
      end
      expect(rendered_component).to have_selector :menuitem, text: I18n.t("types.index.make_default")
      expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_delete)
    end

    it "points make default at the variant, not at its type" do
      expect(rendered_component).to have_css(
        "form[action='#{make_default_type_variant_path(type_id: root_type.id, id: variant.id)}']"
      )
    end

    # A new project would start on a configuration only the owning project can see, so this is
    # not an action a project-owned variant has. TypeVariant refuses it as well.
    context "when a project owns the variant" do
      shared_let(:owned) do
        create(:project_owned_type_variant, type: root_type, project: create(:project), variant_name: "Internal")
      end

      subject(:rendered_component) { render_inline(described_class.new(variant: owned)) }

      it "offers no activating in new projects", :aggregate_failures do
        expect(rendered_component).to have_no_selector :menuitem, text: I18n.t("types.index.make_default")
        expect(rendered_component).to have_no_selector :menuitem, text: I18n.t("types.index.remove_default")
      end

      it "still offers configuring and deleting it", :aggregate_failures do
        expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_configure)
        expect(rendered_component).to have_selector :menuitem, text: I18n.t(:button_delete)
      end
    end

    context "when the variant is the one new projects start with" do
      before { variant.update!(enabled_in_new_projects: true) }

      it "offers removing the default instead of setting it", :aggregate_failures do
        expect(rendered_component).to have_selector :menuitem, text: I18n.t("types.index.remove_default")
        expect(rendered_component).to have_no_selector :menuitem, text: I18n.t("types.index.make_default")
      end
    end

    describe "deleting" do
      context "when no project applies the variant" do
        it "deletes it directly, behind a confirmation" do
          rendered_component

          expect(page).to have_css(
            "form[action='#{type_variant_path(type_id: root_type.id, id: variant.id)}'][data-turbo-confirm]"
          )
        end
      end

      context "when projects apply the variant" do
        before do
          project = create(:project, types: [root_type])
          project.project_types.find_by(type: root_type).update!(variant:)
        end

        it "opens the migration dialog instead of deleting straight away", :aggregate_failures do
          rendered_component
          link = page.find_link(I18n.t(:button_delete))

          expect(link[:href]).to eq deletion_dialog_type_variant_path(type_id: root_type.id, id: variant.id)
          expect(link["data-controller"]).to eq("async-dialog")
        end
      end
    end
  end
end
