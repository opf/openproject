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

RSpec.describe API::V3::WorkPackages::WorkPackageSumsRepresenter,
               with_settings: { costs_currency: "EUR", costs_currency_format: "%n %u" } do
  let(:sums) do
    API::ParserStruct.new(
      material_costs: 5,
      labor_costs: 10.5,
      overall_costs: 15.5,
      available_custom_fields: []
    )
  end
  let(:current_user) { build_stubbed(:user) }
  let(:representer) do
    described_class.create(sums, current_user)
  end

  subject { representer.to_json }

  it "renders the material costs in the configured currency" do
    expect(subject).to be_json_eql("5.00 EUR".to_json).at_path("materialCosts")
  end

  it "renders the labor costs in the configured currency" do
    expect(subject).to be_json_eql("10.50 EUR".to_json).at_path("laborCosts")
  end

  it "renders the overall costs in the configured currency" do
    expect(subject).to be_json_eql("15.50 EUR".to_json).at_path("overallCosts")
  end
end
