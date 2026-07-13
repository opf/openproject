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

RSpec.shared_context "with rendered filter input form" do
  include ViewComponent::TestHelpers

  let(:additional_attributes) { {} }
  let(:active) { true }

  def vc_render_filter_form(
    form_class = described_class,
    filter: self.filter,
    additional_attributes: self.additional_attributes,
    active: self.active
  )
    render_in_view_context(form_class, filter, additional_attributes, active) do |form_class, filter, attrs, active|
      primer_form_with(url: "/test", method: :post) do |f|
        render(form_class.new(f, filter:, additional_attributes: attrs, active:))
      end
    end
  end

  subject(:rendered_form) do
    vc_render_filter_form
    page
  end

  shared_examples "rendering filter row" do
    it "renders a filter row with data attributes" do
      expect(rendered_form).to have_element "data-filter--filters-form-target": "filter",
                                            "data-filter-name": filter.name.to_s
    end

    it "renders a label with the filter's human name" do
      expect(rendered_form).to have_element :label, text: filter.human_name
    end

    it "renders a delete button" do
      expect(rendered_form).to have_element "data-action": /filter--filters-form#removeFilter/
    end
  end

  shared_examples "rendering operator select" do
    it "renders an operator select with available operators" do
      expect(rendered_form).to have_select "operator_#{filter.name}" do |select|
        filter.available_operators.each do |op|
          expect(select).to have_selector :option, text: op.human_name
        end
      end
    end
  end

  shared_examples "hidden when inactive" do
    context "when inactive" do
      let(:active) { false }

      it "renders the row with hidden attribute" do
        expect(rendered_form).to have_element "data-filter--filters-form-target": "filter",
                                              "data-filter-name": filter.name.to_s,
                                              hidden: "hidden",
                                              visible: :all
      end
    end
  end
end
