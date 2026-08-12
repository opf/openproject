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

RSpec.describe Filters::Inputs::BaseFilterForm, type: :forms do
  include ViewComponent::TestHelpers

  let!(:date_field) { create(:user_custom_field, field_format: "date") }
  let(:query) { UserQuery.new }
  let(:filter) { query.available_advanced_filters.find { |af| af.name == :"cf_#{date_field.id}" } }
  let(:active) { true }

  # Concrete subclass so the abstract base can be rendered: BaseFilterForm#add_operand
  # raises SubclassResponsibilityError, so every real subclass supplies an operand.
  let(:form_class) do
    Class.new(described_class) do
      def add_operand(group)
        group.text_field(name: operand_name, label: @filter.human_name)
      end
    end
  end

  def render_base_form(form_class: self.form_class, filter: self.filter, active: self.active)
    render_in_view_context(form_class, filter, active) do |form_class, filter, active|
      primer_form_with(url: "/test", method: :post) do |f|
        render(form_class.new(f, filter:, additional_attributes: {}, active:))
      end
    end
    page
  end

  subject(:rendered_form) { render_base_form }

  it "renders the row group with filter data attributes" do
    expect(rendered_form).to have_element "data-filter--filters-form-target": "filter",
                                          "data-filter-name": filter.name.to_s,
                                          "data-filter-type": filter.type.to_s
  end

  it "renders the operator select with the filter's operators" do
    expect(rendered_form).to have_select "operator_#{filter.name}" do |select|
      filter.available_operators.each do |op|
        expect(select).to have_selector :option, text: op.human_name
      end
    end
  end

  it "marks value-less operators with data-no-value and leaves the rest untouched" do
    select = rendered_form.find(:select, "operator_#{filter.name}", visible: :all)

    filter.available_operators.each do |op|
      option = select.find(:element, :option, value: op.symbol, visible: :all)

      if op.requires_value?
        expect(option["data-no-value"]).to be_nil
      else
        expect(option["data-no-value"]).to eq("true")
      end
    end
  end

  it "points the label at the operator select for a non-boolean filter" do
    expect(rendered_form).to have_element :label,
                                          text: filter.human_name,
                                          for: "operator_#{filter.name}"
  end

  it "renders a delete button within the filter row" do
    expect(rendered_form).to have_element "data-filter--filters-form-target": "filter" do |row|
      expect(row).to have_element "tool-tip", text: I18n.t("button_delete")
    end
  end

  context "when inactive" do
    let(:active) { false }

    it "hides the row" do
      expect(rendered_form).to have_element "data-filter--filters-form-target": "filter",
                                            "data-filter-name": filter.name.to_s,
                                            hidden: "hidden",
                                            visible: :all
    end
  end

  context "with a boolean filter" do
    let!(:bool_field) { create(:user_custom_field, field_format: "bool") }
    let(:filter) { query.available_advanced_filters.find { |af| af.name == :"cf_#{bool_field.id}" } }

    it "hides the operator select" do
      expect(rendered_form).to have_select "operator_#{filter.name}", visible: :hidden
    end
  end

  context "when add_operand is not overridden" do
    let(:form_class) { Class.new(described_class) }

    it "raises SubclassResponsibilityError when rendered" do
      expect { render_base_form }.to raise_error(SubclassResponsibilityError)
    end
  end
end
