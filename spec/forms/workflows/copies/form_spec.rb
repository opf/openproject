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

RSpec.describe Workflows::Copies::Form, type: :forms do
  include_context "with rendered form"

  let(:model) { false }
  let(:params) { { all_roles: } }
  let(:all_roles) { create_list(:project_role, 4) }

  it "renders the Target roles autocompleter" do
    data_attributes = "[data-test-selector=\"target_roles_autocomplete\"][data-multiple=\"true\"]"
    expect(page).to have_css "opce-autocompleter#{data_attributes}" do |autocompleter|
      options_text = JSON.parse(autocompleter["data-items"]).map { |item| item["name"] }
      expect(options_text).to match_array(all_roles.map(&:name))
    end
  end

  it "offers no mode choice or source picker" do
    expect(page).to have_no_field("Copy to another type")
    expect(page).to have_no_css "opce-autocompleter[data-test-selector=\"target_types_autocomplete\"]"
    expect(page).to have_no_select "Source role"
  end
end
