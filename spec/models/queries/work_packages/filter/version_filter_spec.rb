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

RSpec.describe Queries::WorkPackages::Filter::VersionFilter do
  let(:actual_project) { create(:project) }
  let(:version) { create(:version, project: actual_project) }
  let(:other_project_version) { create(:version, project: create(:project)) }

  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:user) { create(:user, member_with_roles: { actual_project => role }) }

  before { login_as(user) }

  it_behaves_like "basic query filter" do
    let(:project) { actual_project }
    let(:type) { :list_optional }
    let(:class_key) { :version_id }
    let(:values) { [version.id.to_s] }
    let(:name) { WorkPackage.human_attribute_name("version") }

    describe "#available?" do
      context "with the setting enabled",
              with_settings: { work_package_multiple_versions: true } do
        it "is not available" do
          expect(instance).not_to be_available
        end
      end

      context "with the setting disabled",
              with_settings: { work_package_multiple_versions: false } do
        it "is available" do
          expect(instance).to be_available
        end
      end
    end

    describe "#valid?" do
      context "within a project" do
        context "and the version belongs to the project" do
          it "is valid" do
            expect(instance).to be_valid
          end
        end

        context "and the version is from another project" do
          let(:values) { [other_project_version.id.to_s] }

          it "is not valid" do
            expect(instance).not_to be_valid
          end
        end
      end

      context "without a project" do
        let(:project) { nil }

        context "and the version is visible to the user" do
          it "is valid" do
            expect(instance).to be_valid
          end
        end

        context "and the version does not exist" do
          let(:values) { ["12345"] }

          it "is not valid" do
            expect(instance).not_to be_valid
          end
        end
      end
    end

    describe "#allowed_values" do
      it_behaves_like "version filter allowed values"
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe "#value_objects" do
      let!(:other_version) { create(:version, project: actual_project) }

      it "returns the Version records matching the filter values" do
        expect(instance.value_objects).to contain_exactly(version)
      end
    end

    describe "#available_operators" do
      it "includes the version status operators" do
        expect(instance.available_operators).to include(
          Queries::Operators::Versions::OpenStatus,
          Queries::Operators::Versions::ClosedStatus,
          Queries::Operators::Versions::LockedStatus
        )
      end
    end

    describe "#operator_strategy" do
      context "for open status operator" do
        let(:operator) { "o" }

        it "returns OpenStatus operator" do
          expect(instance.operator_strategy).to eq(Queries::Operators::Versions::OpenStatus)
        end
      end

      context "for closed status operator" do
        let(:operator) { "c" }

        it "returns ClosedStatus operator" do
          expect(instance.operator_strategy).to eq(Queries::Operators::Versions::ClosedStatus)
        end
      end

      context "for locked status operator" do
        let(:operator) { "l" }

        it "returns LockedStatus operator" do
          expect(instance.operator_strategy).to eq(Queries::Operators::Versions::LockedStatus)
        end
      end
    end

    describe "#joins" do
      %w[= ! * !* o c l].each do |op|
        context "with operator '#{op}'" do
          let(:operator) { op }

          it "returns nil, as the conditions are self-contained subqueries" do
            expect(instance.joins).to be_nil
          end
        end
      end
    end

    describe "#where" do
      let(:where_project) { create(:project) }
      let(:open_version) { create(:version, project: where_project) }
      let(:closed_version) { create(:version, project: where_project, status: "closed") }

      let!(:wp_targeting_open) do
        create(:work_package, project: where_project).tap do |wp|
          create(:work_package_version, work_package: wp, version: open_version, kind: :target)
        end
      end
      let!(:wp_targeting_closed) do
        create(:work_package, project: where_project).tap do |wp|
          create(:work_package_version, work_package: wp, version: closed_version, kind: :target)
        end
      end
      let!(:wp_observed_only) do
        create(:work_package, project: where_project).tap do |wp|
          create(:work_package_version, work_package: wp, version: open_version, kind: :observed_in)
        end
      end
      let!(:wp_without_versions) { create(:work_package, project: where_project) }

      subject(:result) { WorkPackage.where(instance.where) }

      it "does not filter on the version_id column" do
        expect(instance.where)
          .not_to include("#{WorkPackage.table_name}.version_id")
      end

      context 'for "=" with a version' do
        let(:values) { [open_version.id.to_s] }

        it "returns work packages targeting that version" do
          expect(result).to contain_exactly(wp_targeting_open)
        end
      end

      context 'for "!" with a version' do
        let(:operator) { "!" }
        let(:values) { [open_version.id.to_s] }

        it "returns work packages not targeting that version, including ones without target versions" do
          expect(result).to contain_exactly(wp_targeting_closed, wp_observed_only, wp_without_versions)
        end
      end

      context 'for "*" (any target version)' do
        let(:operator) { "*" }
        let(:values) { [] }

        it "returns work packages with at least one target version" do
          expect(result).to contain_exactly(wp_targeting_open, wp_targeting_closed)
        end
      end

      context 'for "!*" (no target version)' do
        let(:operator) { "!*" }
        let(:values) { [] }

        it "returns work packages without any target version" do
          expect(result).to contain_exactly(wp_observed_only, wp_without_versions)
        end
      end

      context 'for "o" (open version)' do
        let(:operator) { "o" }
        let(:values) { [] }

        it "returns work packages targeting an open version" do
          expect(result).to contain_exactly(wp_targeting_open)
        end
      end

      context 'for "c" (closed version)' do
        let(:operator) { "c" }
        let(:values) { [] }

        it "returns work packages targeting a closed version" do
          expect(result).to contain_exactly(wp_targeting_closed)
        end
      end
    end
  end
end
