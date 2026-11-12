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

RSpec.describe EnterpriseHelper do
  describe "#enterprise_token_plan_name" do
    let(:token) { instance_double(EnterpriseToken, plan: :legacy_enterprise, version: "4.0.0") }

    it "returns the plan name" do
      expect(helper.enterprise_token_plan_name(token)).to eq("Enterprise Plan")
    end
  end

  describe "#enterprise_plan_additional_features" do
    context "without any additional features" do
      let(:token) { instance_double(EnterpriseToken, features: []) }

      it "returns an empty string" do
        expect(helper.enterprise_plan_additional_features(token)).to eq("")
      end
    end

    context "with known additional features" do
      let(:token) { instance_double(EnterpriseToken, features: %i[baseline_comparison virus_scanning]) }

      it "returns translated names of features" do
        expect(helper.enterprise_plan_additional_features(token)).to eq("Antivirus Scanning, Baseline Comparisons")
      end
    end

    context "with known and unknown additional features" do
      let(:token) do
        instance_double(EnterpriseToken,
                        features: %i[work_package_sharing this_feature_does_not_exist and_this_one_also_does_not_exist])
      end

      it "returns translated names of features and removes unknowns" do
        expect(helper.enterprise_plan_additional_features(token)).to eq("Share work packages with external users")
      end
    end
  end
end
