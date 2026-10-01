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
end
