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
RSpec.shared_context "with rendered custom field input form" do
  extend DeprecatedAlias
  include ViewComponent::TestHelpers

  let(:model) { create(:project) }
  let!(:custom_field_mapping) do
    create(:project_custom_field_project_mapping, project: model, project_custom_field: custom_field)
  end
  let(:value) { nil }

  current_user { build_stubbed(:admin) }

  def build_form(builder)
    described_class.new(builder, custom_field:, object: model)
  end

  def vc_render_form
    render_in_view_context(model, self) do |model, spec_context|
      primer_form_with(url: "/foo", model:) do |f|
        render(spec_context.build_form(f))
      end
    end
  end

  deprecated_alias :render_form, :vc_render_form

  before do
    model.custom_field_values = { "#{custom_field.id}": value } if value
    model.custom_field_values.first.valid?
  end

  subject(:rendered_form) do
    vc_render_form
    page
  end

  shared_examples "rendering label" do |label_text|
    it "renders a label" do
      expect(rendered_form).to have_element :label, text: label_text
    end
  end

  shared_examples "rendering autocompleter" do |label_text, tag_name: "opce-autocompleter", multiple: false|
    let(:label_id) { rendered_form.find(:element, :label, text: label_text)["for"] }
    let(:autocompleter) { rendered_form.find(:element, tag_name, "data-label-for-id": "\"#{label_id}\"") }

    it "renders autocompleter field" do
      expect(rendered_form).to have_element tag_name, "data-label-for-id": "\"#{label_id}\"" do |autocompleter|
        expect(autocompleter["data-multiple"]).to be_json_eql(multiple)
      end
    end
  end

  shared_examples "rendering label with help text" do |label_text|
    let(:label) { rendered_form.find(:element, :label, text: label_text) }

    include_examples "rendering label", label_text

    context "without attribute help text" do
      it "does not render help text link" do
        expect(label).to have_no_link class: "op-attribute-help-text"
      end
    end

    context "with attribute help text" do
      let!(:attribute_help_text) { create(:project_help_text, attribute_name: custom_field.attribute_name) }

      it "renders help text link" do
        expect(label).to have_link class: "op-attribute-help-text"
      end
    end
  end
end
