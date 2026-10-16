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

RSpec.describe DevelopmentData::TeamSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:admin) { create(:admin) }
  let(:seed_data) { Source::SeedData.new(data_hash).tap { it.store_reference(:openproject_admin, admin) } }
  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      development_teams:
      - reference: :team__comms
        name: COMMS
        members:
          - :openproject_admin
    SEEDING_DATA_YAML
  end

  it "creates the team as a group that is not a department, with its members" do
    seeder.seed!

    team = Group.find_by!(lastname: "COMMS")
    expect(team).not_to be_organizational_unit
    expect(team.users).to contain_exactly(admin)
    expect(seed_data.find_reference(:team__comms)).to eq(team)
  end

  it "does not seed a second time" do
    create(:group, lastname: "COMMS")

    expect(seeder).not_to be_applicable
  end
end
