# --copyright
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
# ++
require "spec_helper"

RSpec.describe OpenProject::FeatureDecisions, :settings_reset do
  let(:flag_name) { :example_flag }

  include_context "with clean feature decisions"

  shared_context "when adding without env variable" do
    before do
      described_class.add flag_name
    end
  end

  shared_context "when adding the given feature flag" do
    before do
      described_class.add flag_name
    end
  end

  describe "`flag_name`_active?" do
    context "without an ENV variable" do
      include_context "when adding without env variable"

      it "is false by default" do
        expect(described_class.send(:"#{flag_name}_active?"))
          .to be false
      end
    end

    context "with an ENV variable (set to true)",
            with_env: { "OPENPROJECT_FEATURE_EXAMPLE_FLAG_ACTIVE" => "true" } do
      include_context "when adding the given feature flag"

      it "is true" do
        expect(described_class.send(:"#{flag_name}_active?"))
          .to be true
      end
    end
  end

  describe "active" do
    context "without any flags defined" do
      it "returns an empty array" do
        expect(described_class.active)
          .to eq []
      end
    end

    context "with a flag defined but not enabled" do
      include_context "when adding without env variable"

      it "returns an empty array" do
        expect(described_class.active)
          .to eq []
      end
    end

    context "with a flag defined that is enabled via env",
            with_env: { "OPENPROJECT_FEATURE_EXAMPLE_FLAG_ACTIVE" => "true" } do
      include_context "when adding the given feature flag"

      it "returns an empty array" do
        expect(described_class.active)
          .to eq [flag_name.to_s]
      end
    end
  end
end
