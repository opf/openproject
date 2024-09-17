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

RSpec.describe API::V3::CostTypes::CostTypeRepresenter do
  include API::V3::Utilities::PathHelper

  let(:cost_type) { build_stubbed(:cost_type) }
  let(:representer) { described_class.new(cost_type, current_user: double("current_user")) }

  subject { representer.to_json }

  it "has a type" do
    expect(subject).to be_json_eql("CostType".to_json).at_path("_type")
  end

  it_behaves_like "has a titled link" do
    let(:link) { "self" }
    let(:href) { api_v3_paths.cost_type cost_type.id }
    let(:title) { cost_type.name }
  end

  it "has an id" do
    expect(subject).to be_json_eql(cost_type.id.to_json).at_path("id")
  end

  it "has a name" do
    expect(subject).to be_json_eql(cost_type.name.to_json).at_path("name")
  end

  it "has a unit" do
    expect(subject).to be_json_eql(cost_type.unit.to_json).at_path("unit")
  end

  it "has a pluralized unit" do
    expect(subject).to be_json_eql(cost_type.unit_plural.to_json).at_path("unitPlural")
  end

  it "indicates if it is the default" do
    expect(subject).to be_json_eql(cost_type.default.to_json).at_path("isDefault")
  end
end
