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

require "spec_helper"

RSpec.describe CustomOptions::CreateService do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let(:allow_additional_project_values) { true }
  let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Berlin Munich], allow_additional_project_values:) }

  subject(:result) { described_class.new(user: admin).call(custom_field:, value: "Hamburg", project:) }

  it "creates a project option at the end of the list", :aggregate_failures do
    expect(result).to be_success
    expect(result.result).to have_attributes(value: "Hamburg", project:, position: 3)
    expect(custom_field.custom_options.reload.map(&:value)).to eq(%w[Berlin Munich Hamburg])
  end

  context "when the custom field does not allow additional project values" do
    let(:allow_additional_project_values) { false }

    it "fails without creating an option", :aggregate_failures do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:project_id)).to include(:additional_values_not_allowed)
      expect(custom_field.custom_options.reload.count).to eq(2)
    end
  end
end
