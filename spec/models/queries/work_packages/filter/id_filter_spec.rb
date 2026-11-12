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

RSpec.describe Queries::WorkPackages::Filter::IdFilter do
  it_behaves_like "filter by work package id" do
    let(:class_key) { :id }

    describe "#where" do
      let!(:visible_wp) { create(:work_package) }
      let!(:other_wp) { create(:work_package) }

      before do
        instance.values = [visible_wp.id.to_s]
        instance.operator = "="
      end

      it "filters" do
        expect(WorkPackage.where(instance.where))
          .to contain_exactly(visible_wp)
      end
    end
  end

  describe "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
    let!(:user) { create(:admin) }
    let!(:project) { create(:project, identifier: "PROJ") }
    let!(:other_project) { create(:project, identifier: "OTHER") }
    let!(:wp1) { create(:work_package, project:) }
    let!(:wp2) { create(:work_package, project:) }
    let!(:other_wp) { create(:work_package, project: other_project) }

    let(:query) { build_stubbed(:query, project: nil) }
    let(:operator) { "=" }
    let(:values) { [] }
    let(:instance) do
      described_class.create!(name: :id, context: query, operator:, values:)
    end

    current_user { user }

    describe "#where" do
      context "with semantic identifiers mixed with numeric ids" do
        let(:values) { [wp1.identifier, other_wp.id.to_s] }

        it "matches the work packages" do
          expect(WorkPackage.where(instance.where)).to contain_exactly(wp1, other_wp)
        end
      end

      context "with a former identifier" do
        let(:values) { ["OLD-1"] }

        before { create(:work_package_semantic_alias, work_package: wp2, identifier: "OLD-1") }

        it "matches the work package" do
          expect(instance).to be_valid
          expect(WorkPackage.where(instance.where)).to contain_exactly(wp2)
        end
      end

      context "with a former identifier based on a classic project identifier" do
        let(:values) { ["my-project-7"] }

        before { create(:work_package_semantic_alias, work_package: wp2, identifier: "my-project-7") }

        it "matches the work package" do
          expect(instance).to be_valid
          expect(WorkPackage.where(instance.where)).to contain_exactly(wp2)
        end
      end

      context "with an identifier that is a prefix of another identifier" do
        let(:values) { ["PROJ-1"] }

        before { create(:work_package_semantic_alias, work_package: wp2, identifier: "PROJ-10") }

        it "matches only the exact identifier" do
          expect(WorkPackage.where(instance.where)).to contain_exactly(wp1)
        end
      end

      context "with the '!' operator" do
        let(:operator) { "!" }
        let(:values) { [wp1.identifier] }

        it "excludes the work package" do
          expect(WorkPackage.where(instance.where)).to contain_exactly(wp2, other_wp)
        end
      end
    end

    describe "#valid?" do
      context "with visible semantic identifiers and numeric ids" do
        let(:values) { [wp1.identifier, wp2.id.to_s] }

        it { expect(instance).to be_valid }
      end

      context "with an unknown semantic identifier" do
        let(:values) { [wp1.identifier, "PROJ-999"] }

        it { expect(instance).not_to be_valid }
      end

      context "with a work package outside of the query project" do
        let(:query) { build_stubbed(:query, project:) }
        let(:values) { [other_wp.identifier] }

        it { expect(instance).not_to be_valid }
      end

      context "with a work package the user cannot see" do
        let(:values) { [wp1.identifier] }

        current_user { create(:user) }

        it { expect(instance).not_to be_valid }
      end
    end

    describe "#value_objects" do
      let(:values) { [wp1.identifier, other_wp.id.to_s] }

      it "returns the work packages" do
        expect(instance.value_objects).to contain_exactly(wp1, other_wp)
      end
    end
  end
end
