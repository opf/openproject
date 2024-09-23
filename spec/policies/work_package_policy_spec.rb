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

RSpec.describe WorkPackagePolicy, type: :controller do
  let(:user)         { build_stubbed(:user) }
  let(:project)      { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }

  describe "#allowed?" do
    let(:subject) { described_class.new(user) }

    context "for edit" do
      it "is false if the user has no permissions" do
        mock_permissions_for(user, &:forbid_everything)
        expect(subject).not_to be_allowed(work_package, :edit)
      end

      it "is true if the user has the edit_work_package permission" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :edit_work_packages, project:
        end

        expect(subject).to be_allowed(work_package, :edit)
      end

      it "is true if the user has the edit_work_package permission on the work packge" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_work_package :edit_work_packages, work_package:
        end

        expect(subject).to be_allowed(work_package, :edit)
      end

      it "is false if the user has only the add_work_package_notes permission" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :add_work_package_notes, project:
        end

        expect(subject).not_to be_allowed(work_package, :edit)
      end

      it "is false if the user has the permissions but the work package is unpersisted" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :edit_work_packages, :add_work_package_notes, project:
        end

        allow(work_package).to receive(:persisted?).and_return false

        expect(subject).not_to be_allowed(work_package, :edit)
      end
    end

    context "for manage_subtasks" do
      it "is true if the user has the manage_subtasks permission in the project" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :manage_subtasks, project:
        end

        expect(subject).to be_allowed(work_package, :manage_subtasks)
      end
    end

    context "for comment" do
      it "is false if the user lacks permission" do
        expect(subject).not_to be_allowed(work_package, :comment)
      end

      it "is true if the user has the add_work_package_notes permission" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :add_work_package_notes, project:
        end
        expect(subject).to be_allowed(work_package, :comment)
      end

      it "is true if the user has the add_work_package_notes permission on the work package" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_work_package :add_work_package_notes, work_package:
        end
        expect(subject).to be_allowed(work_package, :comment)
      end

      it "is true if the user has the edit_work_packages permission" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :edit_work_packages, project:
        end

        expect(subject).to be_allowed(work_package, :comment)
      end

      it "is false if the user has the edit_work_packages permission but the work_package is unpersisted" do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :edit_work_packages, project:
        end
        allow(work_package).to receive(:persisted?).and_return false

        expect(subject).not_to be_allowed(work_package, :comment)
      end
    end
  end
end
