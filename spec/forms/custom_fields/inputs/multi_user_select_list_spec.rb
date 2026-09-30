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

RSpec.describe CustomFields::Inputs::MultiUserSelectList, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) { create(:user_project_custom_field, name: "Users field", multi_value: true) }
  let(:value) { create_list(:user, 2) }

  it_behaves_like "rendering label with help text", "Users field"
  it_behaves_like "rendering autocompleter", "Users field", tag_name: "opce-user-autocompleter", multiple: true do
    it "sets correct autocompleter inputs" do
      expect(autocompleter["data-resource"]).to be_json_eql(%{"principals"})
      expect(autocompleter["data-url"]).to be_json_eql(%{"/api/v3/principals"})
      expect(autocompleter["data-input-value"]).to have_json_size(2)
      expect(autocompleter["data-input-value"]).to be_json_eql(value.pluck(:id).map(&:to_s).to_json)
    end
  end
end
