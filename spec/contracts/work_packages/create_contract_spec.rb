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
require "contracts/work_packages/shared_base_contract"

RSpec.describe WorkPackages::CreateContract do
  let(:work_package) do
    WorkPackage.new(project: work_package_project) do |wp|
      wp.extend(OpenProject::ChangedBySystem)
    end
  end
  let(:validated_contract) do
    contract = subject
    contract.validate
    contract
  end
  let(:work_package_project) { project }
  let(:project) { build_stubbed(:project) }
  let(:other_project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  subject(:contract) { described_class.new(work_package, user) }

  it_behaves_like "work package contract"

  describe "authorization" do
    context "when user allowed in project and project specified" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :add_work_packages, project:
        end

        work_package.project = project
      end

      it "has no authorization error" do
        expect(validated_contract.errors[:base]).to be_empty
      end
    end

    context "when user not allowed in project and project specified" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :add_work_packages, project: other_project
        end

        work_package.project = project
      end

      it "is not authorized" do
        expect(validated_contract.errors.symbols_for(:base))
          .to contain_exactly(:error_unauthorized)
      end
    end

    context "when user allowed in a project and no project specified" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :add_work_packages, project:
        end
      end

      it "has no authorization error" do
        expect(validated_contract.errors[:base]).to be_empty
      end
    end

    context "when user not allowed in any projects and no project specified" do
      before do
        mock_permissions_for(user, &:forbid_everything)
      end

      it "is not authorized" do
        expect(validated_contract.errors.symbols_for(:base))
          .to contain_exactly(:error_unauthorized)
      end
    end

    context "when user not allowed in any projects and project specified" do
      before do
        mock_permissions_for(user, &:forbid_everything)

        work_package.project = project
      end

      it "is not authorized" do
        expect(validated_contract.errors.symbols_for(:base))
          .to contain_exactly(:error_unauthorized)
      end
    end
  end

  describe "remaining hours" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project :add_work_packages, project:
      end
      work_package.project = project
    end

    context "when not changed" do
      it("is valid") { expect(validated_contract.errors[:remaining_hours]).to be_empty }
    end

    context "when changed" do
      before do
        work_package.remaining_hours = 10
      end

      it("is valid") { expect(validated_contract.errors[:remaining_hours]).to be_empty }
    end
  end

  describe "writing read-only attributes" do
    shared_examples "can write" do |attribute, value|
      it "can write #{attribute}", :aggregate_failures do
        expect(contract.writable_attributes).to include(attribute.to_s)

        work_package.send(:"#{attribute}=", value)
        expect(validated_contract.errors[attribute]).to be_empty
      end
    end

    shared_examples "can not write" do |attribute, value|
      it "can not write #{attribute}", :aggregate_failures do
        expect(contract.writable_attributes).not_to include(attribute.to_s)

        work_package.send(:"#{attribute}=", value)
        expect(validated_contract).not_to be_valid
        expect(validated_contract.errors[attribute]).to include "was attempted to be written but is not writable."
      end
    end

    context "when enabled for admin", with_settings: { apiv3_write_readonly_attributes: true } do
      let(:user) { build_stubbed(:admin) }

      it_behaves_like "can write", :created_at, 1.day.ago
      it_behaves_like "can not write", :updated_at, 1.day.ago
      it_behaves_like "can write", :author_id, 1234
    end

    context "when disabled for admin", with_settings: { apiv3_write_readonly_attributes: false } do
      let(:user) { build_stubbed(:admin) }

      it_behaves_like "can not write", :created_at, 1.day.ago
      it_behaves_like "can not write", :updated_at, 1.day.ago
      it_behaves_like "can not write", :author_id, 1234
    end

    context "when enabled for regular user", with_settings: { apiv3_write_readonly_attributes: true } do
      it_behaves_like "can not write", :created_at, 1.day.ago
      it_behaves_like "can not write", :updated_at, 1.day.ago
      it_behaves_like "can not write", :author_id, 1234
    end

    context "when disabled for regular user", with_settings: { apiv3_write_readonly_attributes: false } do
      it_behaves_like "can not write", :created_at, 1.day.ago
      it_behaves_like "can not write", :updated_at, 1.day.ago
      it_behaves_like "can not write", :author_id, 1234
    end
  end
end
