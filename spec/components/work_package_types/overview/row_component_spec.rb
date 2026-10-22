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

require "rails_helper"

RSpec.describe WorkPackageTypes::Overview::RowComponent,
               type: :component do
  include Rails.application.routes.url_helpers

  include_context "with variant scope"

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { type.default_variant }

  let(:aspect) { TypeVariant::DEFAULTS }
  let(:tab) { { name: "defaults", path: "/defaults", label: "Defaults", aspect: } }
  let(:table) { WorkPackageTypes::Overview::TableComponent.new(variant:, tabs: [tab]) }

  subject(:row) { described_class.new(row: tab, table:) }

  describe "the setting" do
    it "links to its own tab" do
      render_inline(row)

      expect(page).to have_link("Defaults", href: "/defaults")
    end
  end

  describe "the configuration mode" do
    context "when the setting cannot be reused" do
      let(:aspect) { nil }

      it "reads always manual" do
        render_inline(row)

        expect(page).to have_text("Always manual")
      end
    end

    context "when a reusable setting is not inherited" do
      it "reads manually configured" do
        render_inline(row)

        expect(page).to have_text("Manually configured")
      end
    end

    context "when the setting is inherited" do
      let(:variant) { create(:type_variant, type:) }

      before { link_configuration(variant, aspect:) }

      it "names the base, linking to that setting on it" do
        render_inline(row)

        expect(page).to have_text("Using the same as type")
        expect(page).to have_link(type.default_variant.composite_name,
                                  href: edit_type_defaults_path(type_id: type.id))
      end
    end

    context "when the setting is a form configuration" do
      let(:aspect) { nil }
      let(:tab) { { name: "form_configuration", path: "/forms", label: "Form", aspect: } }

      it "names the form it uses, linking to that form" do
        render_inline(row)

        expect(page).to have_text("Using form")
        expect(page).to have_link(variant.form_configuration.name,
                                  href: edit_form_configuration_path(variant.form_configuration))
      end
    end

    context "when the setting is a workflow" do
      let(:aspect) { nil }
      let(:tab) { { name: "workflow", path: "/workflow", label: "Workflow", aspect: } }

      it "names the workflow it uses, linking to that workflow" do
        render_inline(row)

        expect(page).to have_text("Using workflow")
        expect(page).to have_link(variant.workflow.name,
                                  href: edit_workflow_path(variant.workflow))
      end
    end
  end
end
