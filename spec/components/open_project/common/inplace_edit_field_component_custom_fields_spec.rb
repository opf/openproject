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

RSpec.describe OpenProject::Common::InplaceEditFieldComponent, type: :component do
  include ViewComponent::TestHelpers

  current_user { build_stubbed(:admin) }

  let(:project) { create(:project) }

  before do
    custom_field
    project.reload
  end

  subject(:rendered_input) do
    render_inline(described_class.new(model: project,
                                      attribute: custom_field.attribute_name.to_sym,
                                      enforce_edit_mode: true))
    page
  end

  {
    string: "Default value",
    integer: 789,
    float: 789.123,
    date: Date.new(2026, 1, 1),
    link: "https://openproject.org",
    text: "Default value"
  }.each do |format, default_value|
    context "with a #{format} custom field" do
      let(:custom_field) { create(:"#{format}_project_custom_field", projects: [project]) }

      it "renders a blank input without a value or default" do
        expect(rendered_input.find_field(custom_field.name, visible: :all).value.to_s).to eq("")
      end

      context "with a default value" do
        let(:custom_field) { super().tap { |field| field.update!(default_value:) } }

        it "renders the default when no value is saved" do
          expect(rendered_input).to have_field(custom_field.name, with: default_value, visible: :all)
        end
      end
    end
  end

  context "with a boolean custom field" do
    let(:custom_field) { create(:boolean_project_custom_field, projects: [project], default_value:) }
    let(:default_value) { nil }

    it "renders an unchecked input without a value or default" do
      expect(rendered_input).to have_unchecked_field(custom_field.name)
    end

    context "with a true default" do
      let(:default_value) { true }

      it "renders a checked input when no value is saved" do
        expect(rendered_input).to have_checked_field(custom_field.name)
      end
    end

    context "with a false default" do
      let(:default_value) { false }

      it "renders an unchecked input when no value is saved" do
        expect(rendered_input).to have_unchecked_field(custom_field.name)
      end
    end
  end

  [false, true].each do |multi_value|
    context "with a #{multi_value ? 'multi' : 'single'} select custom field" do
      let(:custom_field) do
        create(:list_project_custom_field, projects: [project], multi_value:,
                                           possible_values: ["Option 1", "Option 2", "Option 3"])
      end

      let(:default_options) { custom_field.custom_options.first(multi_value ? 2 : 1) }

      before do
        default_options.each { |option| option.update!(default_value: true) }
      end

      it "preselects the default options when no value is saved" do
        model = JSON.parse(rendered_input.find("opce-autocompleter")["data-model"])
        selected = multi_value ? model : [model]

        expect(selected.pluck("name")).to eq(default_options.pluck(:value))
        expect(selected.pluck("selected")).to all(be(true))
      end
    end
  end

  context "with a list custom field that opens in a dialog" do
    let(:custom_field) do
      create(:list_project_custom_field, projects: [project], has_comment: true,
                                         possible_values: ["Option 1", "Option 2"])
    end

    it "includes the selected value in the display and accessible dialog label" do
      create(:custom_value, customized: project, custom_field:, value: custom_field.custom_options.first.id)
      render_inline(described_class.new(model: Project.find(project.id), attribute: custom_field.attribute_name.to_sym))

      display = page.find(".op-inplace-edit--display-field")
      expect(display).to have_text("Option 1")
      expect(display["aria-label"]).to include(I18n.t(:label_value_x, x: "Option 1"))
      expect(display["data-action"]).to include("click->inplace-edit#openDialog")
    end
  end
end
