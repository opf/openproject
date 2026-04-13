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

RSpec.describe Queries::WorkPackages::Filter::TargetVersionsFilter do
  let(:actual_project) { create(:project) }
  let(:version) { create(:version, project: actual_project) }
  let(:other_project_version) { create(:version, project: create(:project)) }

  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:user) { create(:user, member_with_roles: { actual_project => role }) }

  before { login_as(user) }

  it_behaves_like "basic query filter" do
    let(:project) { actual_project }
    let(:type) { :list_optional }
    let(:class_key) { :target_version_id }
    let(:values) { [version.id.to_s] }
    let(:name) { WorkPackage.human_attribute_name("target_versions") }

    describe "#valid?" do
      context "within a project" do
        context "and version is present" do
          it "is valid" do
            expect(instance).to be_valid
          end
        end

        context "and version is from another project" do
          let(:values) { [other_project_version.id.to_s] }

          it "is not valid" do
            expect(instance).not_to be_valid
          end
        end
      end

      context "without a project" do
        let(:project) { nil }

        context "and version is present" do
          it "is valid" do
            expect(instance).to be_valid
          end
        end

        context "and version is invalid" do
          let(:values) { ["12345"] }

          it "is not valid" do
            expect(instance).not_to be_valid
          end
        end
      end
    end

    describe "#allowed_values" do
      context "within a project" do
        it "returns the project's shared versions" do
          expect(instance.allowed_values)
            .to contain_exactly([version.id.to_s, version.id.to_s])
        end
      end

      context "without a project" do
        let(:project) { nil }
        let(:values) { [other_project_version.id.to_s] }

        it "includes versions visible to the current user" do
          expect(instance.allowed_values).to be_empty
        end
      end
    end

    describe "#value_objects" do
      let!(:other_version) { create(:version, project: actual_project) }

      before { instance.values = [version.id.to_s] }

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
  end
end
