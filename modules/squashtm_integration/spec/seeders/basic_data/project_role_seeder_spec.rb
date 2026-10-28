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

require "spec_helper"

RSpec.describe BasicData::ProjectRoleSeeder, "SquashTM permissions" do
  subject(:seeder) { described_class.new(Source::SeedDataLoader.get_data(edition: "standard")) }

  before { seeder.seed! }

  def permissions_of(reference)
    seeder.seed_data.find_reference(reference).permissions
  end

  it "lets readers view SquashTM test results" do
    expect(permissions_of(:default_role_reader)).to include(:view_squashtm_test_results)
    expect(permissions_of(:default_role_reader)).not_to include(:manage_squashtm_links, :manage_squashtm_integration)
  end

  it "lets members view SquashTM test results and link requirements" do
    expect(permissions_of(:default_role_member)).to include(:view_squashtm_test_results, :manage_squashtm_links)
    expect(permissions_of(:default_role_member)).not_to include(:manage_squashtm_integration)
  end

  it "lets project admins manage the SquashTM integration" do
    expect(permissions_of(:default_role_project_admin))
      .to include(:view_squashtm_test_results, :manage_squashtm_links, :manage_squashtm_integration)
  end
end
