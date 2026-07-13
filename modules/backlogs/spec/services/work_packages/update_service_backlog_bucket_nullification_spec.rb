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

RSpec.describe WorkPackages::UpdateService, "backlog bucket nullification on project change", type: :model do
  let(:source_project) { create(:project) }
  let(:target_project) { create(:project) }

  let(:project_permissions) do
    # manage_sprint_items permission is intentionally excluded: nullifying the
    # backlog bucket when a work package is moved to a different project is an
    # consistency measure (backlog buckets are project-scoped), not a
    # user-initiated sprint management action
    %i[
      edit_work_packages
      move_work_packages
      view_work_packages
    ]
  end

  let(:user) do
    create(
      :user,
      member_with_permissions: {
        source_project => project_permissions,
        target_project => project_permissions
      }
    )
  end

  let(:work_package) do
    create(:work_package,
           project: source_project,
           author: user,
           backlog_bucket: backlog_bucket_in_source_project)
  end

  let(:instance) { described_class.new(user:, model: work_package) }

  current_user { user }

  describe "when changing the project" do
    context "when the work package has a backlog bucket" do
      let(:backlog_bucket_in_source_project) do
        create(:backlog_bucket, project: source_project)
      end

      context "when moving to another project" do
        it "nullifies the backlog_bucket_id" do
          result = instance.call(project: target_project)

          expect(result).to be_success
          expect(work_package.reload).to have_attributes(backlog_bucket_id: nil, project: target_project)
        end
      end

      context "when the work package project is NOT changing" do
        it "preserves the backlog_bucket_id" do
          result = instance.call(subject: "Updated Subject")

          expect(result).to be_success
          expect(work_package.reload)
            .to have_attributes(
              backlog_bucket: backlog_bucket_in_source_project,
              project: source_project
            )
        end
      end
    end

    context "when the work package does NOT have a backlog bucket" do
      let(:backlog_bucket_in_source_project) { nil }

      it "keeps backlog_bucket_id nil when moving to another project" do
        result = instance.call(project: target_project)

        expect(result).to be_success
        expect(work_package.reload)
          .to have_attributes(
            backlog_bucket_id: nil,
            project: target_project
          )
      end
    end
  end
end
