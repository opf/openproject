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
require_module_spec_helper

RSpec.describe EnvData::ITSM::HelpdeskUserSeeder, with_flag: { helpdesk: true }, with_settings: { helpdesk_enabled: true } do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new({}) }

  it "sets up the help desk user and role" do
    seeder.seed!

    expect(ITSM.helpdesk_user).to have_attributes(name: "Help desk")
    expect(ITSM.helpdesk_role).to have_attributes(name: "Help desk")
  end

  it "is discovered by the env data seeder" do
    expect(EnvDataSeeder.new(seed_data).discovered_seeders).to include(an_instance_of(described_class))
  end

  context "when the help desk user cannot be set up" do
    before do
      create(:project_role, name: "Help desk")
      allow(Rails.logger).to receive(:error)
    end

    it "logs the failure without raising" do
      expect { seeder.seed! }.not_to raise_error

      expect(ITSM.helpdesk_user).to be_nil
      expect(Rails.logger).to have_received(:error).with(/Help desk user not set up/)
    end
  end

  context "when the help desk is not enabled", with_settings: { helpdesk_enabled: false } do
    it { is_expected.not_to be_applicable }
  end

  context "when the feature flag is inactive", with_flag: { helpdesk: false } do
    it { is_expected.not_to be_applicable }
  end
end
