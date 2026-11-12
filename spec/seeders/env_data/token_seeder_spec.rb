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

RSpec.describe EnvData::TokenSeeder do
  let(:seed_data) { Source::SeedData.new({}) }

  subject(:seeder) { described_class.new(seed_data) }

  context "when not provided" do
    it "does nothing" do
      expect { seeder.seed! }.not_to change(EnterpriseToken, :count)
    end
  end

  context "when providing a seed token",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED__ENTERPRISE__TOKEN: Rails.root.join("spec/fixtures/ee_tokens/v2_1_user_test_host.token").read
          } do
    it "seeds the token" do
      reset(:seed_enterprise_token)
      Setting.host_name = "test.host"
      expect { seeder.seed! }.to change(EnterpriseToken, :count).by(1)
    end

    context "when domain mismatches" do
      it "raises an error" do
        reset(:seed_enterprise_token)
        Setting.host_name = "foo.example.com"
        expect { seeder.seed! }.to raise_error(/Validation failed: Domain is invalid./)
      end
    end
  end
end
