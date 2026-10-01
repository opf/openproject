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

RSpec.describe OpenProject::Common::InplaceEditFields::CalculatedValueInputComponent, type: :component do
  include ViewComponent::TestHelpers

  shared_let(:project) { create(:project) }

  it "renders a readonly text input without buttons" do
    component_class = described_class
    render_in_view_context(project) do |model|
      primer_form_with(url: "/foo", model:) do |f|
        render_inline_form(f) do |form|
          render component_class.new(form:, model:, attribute: :name, label: "Name")
        end
      end
    end

    expect(rendered_content).to have_field("project[name]", type: "text", readonly: true)

    expect(rendered_content).to have_no_button(I18n.t(:button_save))
    expect(rendered_content).to have_no_button(I18n.t(:button_cancel))
  end

  describe "rendering value", with_ee: %i[calculated_values] do
    let(:custom_field) { create(:calculated_value_project_custom_field, projects: [project]) }

    current_user { build_stubbed(:admin) }

    before do
      create(:custom_value, customized: project, custom_field:, value:)
    end

    shared_examples "formats the value" do
      it "renders the formatted custom value" do
        attribute = custom_field.attribute_getter

        component_class = described_class
        render_in_view_context(project) do |model|
          primer_form_with(url: "/foo", model:) do |f|
            render_inline_form(f) do |form|
              render component_class.new(form:, model:, attribute:, label: "Calc")
            end
          end
        end

        expect(rendered_content).to have_field("project[#{attribute}]", type: "text", readonly: true, with: formatted)
      end
    end

    context "for integer value" do
      let(:value) { 42 }
      let(:formatted) { "42" }

      include_examples "formats the value"
    end

    context "for float value" do
      let(:value) { 3.14159 }
      let(:formatted) { "3.142" }

      include_examples "formats the value"
    end

    context "for true value" do
      let(:value) { true }
      let(:formatted) { I18n.t(:general_text_Yes) }

      include_examples "formats the value"
    end

    context "for false value" do
      let(:value) { false }
      let(:formatted) { I18n.t(:general_text_No) }

      include_examples "formats the value"
    end

    context "for no value" do
      let(:value) { nil }
      let(:formatted) { "" }

      include_examples "formats the value"
    end
  end
end
