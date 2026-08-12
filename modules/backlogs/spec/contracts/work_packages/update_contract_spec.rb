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
require_relative "shared_contract_examples"

RSpec.describe WorkPackages::UpdateContract do
  let(:work_package) do
    build_stubbed(:work_package,
                  project: work_package_project,
                  subject: "Some subject",
                  type: work_package_type,
                  priority: work_package_priority,
                  status: work_package_status) do |wp|
      wp.story_points = work_package_story_points
      wp.sprint = work_package_sprint
      wp.extend(OpenProject::ChangedBySystem)
    end
  end

  let(:permissions) do
    %i[
      view_work_packages
      edit_work_packages
      manage_sprint_items
      view_sprints
    ]
  end

  before do
    visible_scope = instance_double(ActiveRecord::Relation)

    allow(WorkPackage)
      .to receive(:visible)
            .with(user)
            .and_return(visible_scope)
    allow(visible_scope)
      .to receive(:exists?)
            .with(work_package.id)
            .and_return(true)
  end

  it_behaves_like "work package contract with backlogs extensions" do
    describe "validations" do
      context "when setting sprint and lock_version " \
              "and only having the manage_sprint_items permission but lacking edit_work_packages" do
        let(:permissions) { %i[view_work_packages manage_sprint_items view_sprints] }

        before do
          # Reverting the change done in the setup
          work_package.restore_attributes([:story_points])
        end

        it_behaves_like "contract is valid"
      end

      context "when setting the sprint and another property " \
              "and only having the manage_sprint_items permission but lacking edit_work_packages" do
        let(:permissions) { %i[view_work_packages manage_sprint_items view_sprints] }

        before do
          work_package.subject = "Some other subject"
        end

        it_behaves_like "contract is invalid",
                        subject: :error_readonly,
                        story_points: :error_readonly
      end

      context "when sprint is not assignable but the assignment did not change" do
        let(:completed_sprint) { build_stubbed(:sprint, status: :completed) }
        let(:work_package_sprint) { completed_sprint }
        let(:assignable_sprints) { [] }

        before do
          # So that the changes look like they came out of the database
          work_package.clear_changes_information
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "writable_attributes" do
      context "when the user has only :manage_sprint_items permission but lacks :edit_work_packages" do
        let(:permissions) { %i[view_work_packages manage_sprint_items view_sprints] }

        it "includes sprint, backlog_bucket and lock_version", :aggregate_failures do
          expect(contract.writable_attributes).to include("backlog_bucket", "sprint", "lock_version")
          expect(contract.writable_attributes).not_to include("story_points", "position")
        end
      end
    end

    describe ".update_allowed?" do
      context "with the user having manage_sprint_items" do
        let(:permissions) { [:manage_sprint_items] }

        it "is allowed" do
          expect(described_class)
            .to be_update_allowed(user:, work_package:)
        end
      end
    end
  end
end
