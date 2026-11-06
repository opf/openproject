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

#
require "spec_helper"

RSpec.describe CustomFields::Inputs::MultiSelectList, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) do
    create(
      :list_project_custom_field,
      name: "Multi-list field",
      multi_value: true,
      possible_values: ["uno", "due", "tre", "quattro"]
    )
  end
  let(:value) { custom_field.possible_values.last(2).pluck(:id) }

  it_behaves_like "rendering label with help text", "Multi-list field"
  it_behaves_like "rendering autocompleter", "Multi-list field", multiple: true do
    it "sets correct autocompleter inputs" do
      expect(autocompleter["data-items"]).to have_json_size(4)
      expect(autocompleter["data-model"]).to have_json_size(2)
      expect(autocompleter["data-model"]).to be_json_eql(%{[{"disabled": false, "name": "tre", "selected": true}, {"disabled": false, "name": "quattro", "selected": true}]})
    end
  end

  context "with a blank stored value" do
    let(:value) { [nil] }

    it "renders no selected option" do
      expect(rendered_form.find("opce-autocompleter")["data-model"]).to be_json_eql([])
    end
  end

  context "for a work package custom field with project-specific values" do
    let(:type) { create(:type) }
    let(:project) { create(:project, types: [type]) }
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist,
             types: [type], name: "Multi-list field", multi_value: true, possible_values: %w[uno due tre])
    end
    let(:option_uno) { custom_field.custom_options.find_by!(value: "uno") }
    let(:option_due) { custom_field.custom_options.find_by!(value: "due") }
    let(:model) do
      create(:work_package, project:, type:, custom_values: { custom_field.id => [option_uno.id.to_s, option_due.id.to_s] })
        .reload
    end
    let(:custom_field_mapping) { nil }
    let(:value) { nil }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_uno)
    end

    it_behaves_like "rendering autocompleter", "Multi-list field", multiple: true do
      it "only offers the usable options and keeps the stored option that is no longer usable selected" do
        placeholder = I18n.t(:label_custom_value_no_longer_available)

        expect(JSON.parse(autocompleter["data-items"]).pluck("name")).to eq(["uno", placeholder])
        expect(JSON.parse(autocompleter["data-model"]).pluck("name")).to contain_exactly("uno", placeholder)
      end
    end
  end
end
