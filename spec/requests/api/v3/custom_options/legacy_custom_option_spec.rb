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
require "rack/test"

RSpec.describe "GET /api/v3/custom_options/:id", :with_no_ee do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:custom_field) do
    cf = create(:list_wp_custom_field, possible_values: %w[pear])
    project.work_package_custom_fields << cf
    cf
  end

  let(:item) { custom_field.possible_values.first }
  let(:legacy_id) { 4242 }

  before do
    CustomField::LegacyOptionMapping.create!(custom_option_id: legacy_id,
                                             hierarchical_item_id: item.id,
                                             custom_field_id: custom_field.id)
    login_as(user)
    get api_v3_paths.custom_option(legacy_id)
  end

  it "still answers with the custom option shape" do
    expect(JSON.parse(last_response.body)).to include("_type" => "CustomOption", "id" => legacy_id, "value" => "pear")
  end

  it "announces the deprecation without committing to a removal date" do
    expect(last_response.headers["Deprecation"]).to eq("true")
    expect(last_response.headers).not_to have_key("Sunset")
  end
end
