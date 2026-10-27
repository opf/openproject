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

RSpec.describe CustomFields::Inputs::SingleSelectList, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) { create(:list_project_custom_field, name: "List field", possible_values: ["eins", "zwei", "drei"]) }
  let(:value) { custom_field.possible_values.first.id }

  it_behaves_like "rendering label with help text", "List field"
  it_behaves_like "rendering autocompleter", "List field" do
    it "sets correct autocompleter inputs" do
      expect(autocompleter["data-items"]).to have_json_size(3)
      expect(autocompleter["data-model"]).to be_json_eql(%{{"disabled": false, "name": "eins", "selected": true}})
    end
  end

  context "when the field is rendered read-only" do
    def build_form(builder)
      described_class.new(builder, custom_field:, object: model, disabled: true)
    end

    it_behaves_like "rendering autocompleter", "List field" do
      it "disables the autocompleter" do
        expect(autocompleter["data-disabled"]).to be_json_eql(true)
      end
    end
  end

  context "with a default value" do
    before do
      custom_field.possible_values[1].update default_value: true
    end

    it_behaves_like "rendering autocompleter", "List field" do
      let(:value) { custom_field.possible_values.last.id }

      ##
      # We specifically test that it doesn't just render the selected option by accident.
      # So we make the last option the selected value with the default being a value
      # before that.
      # This is to rule out the bug (#66433) we had before where both the list items [1] for the
      # default value and the selected value had `selected: true` with the first one
      # 'winning'.
      #
      # [1] CustomFields::Inputs::SingleSelectList#list_items
      describe "with an option selected" do
        it "pre-selects the selected value" do
          expect(autocompleter["data-model"]).to be_json_eql(%{{"disabled": false, "name": "drei", "selected": true}})
        end
      end

      describe "with no option selected" do
        let(:value) { nil }

        it "pre-selects the default value" do
          expect(autocompleter["data-model"]).to be_json_eql(%{{"disabled": false, "name": "zwei", "selected": true}})
        end
      end
    end
  end

  context "for a work package custom field with project-specific values" do
    let(:type) { create(:type) }
    let(:project) { create(:project, types: [type]) }
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist,
             types: [type], name: "List field", possible_values: %w[eins zwei drei])
    end
    let(:option_eins) { custom_field.custom_options.find_by!(value: "eins") }
    let(:option_zwei) { custom_field.custom_options.find_by!(value: "zwei") }
    let(:model) do
      create(:work_package, project:, type:, custom_values: { custom_field.id => option_eins.id.to_s }).reload
    end
    let(:custom_field_mapping) { nil }
    let(:value) { nil }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_eins)
    end

    it_behaves_like "rendering autocompleter", "List field" do
      it "only offers the options usable in the work package's project" do
        expect(JSON.parse(autocompleter["data-items"]).pluck("name")).to eq(%w[eins])
      end
    end

    context "with a stored option that is no longer usable" do
      let(:model) do
        create(:work_package, project:, type:, custom_values: { custom_field.id => option_zwei.id.to_s }).reload
      end

      it_behaves_like "rendering autocompleter", "List field" do
        it "keeps the stored option selected under the placeholder" do
          placeholder = I18n.t(:label_custom_value_no_longer_available)

          expect(JSON.parse(autocompleter["data-items"]).pluck("name")).to eq(["eins", placeholder])
          expect(autocompleter["data-model"]).to be_json_eql(%{{"disabled": false, "name": "#{placeholder}", "selected": true}})
        end
      end
    end
  end
end
