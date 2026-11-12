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

RSpec.describe Activities::Fetcher, "integration" do
  shared_let(:user) { create(:user) }
  shared_let(:permissions) do
    %i[view_work_packages view_time_entries view_changesets view_wiki_edits view_internal_comments]
  end
  shared_let(:role) { create(:project_role, permissions:) }
  # execute as user so that the user is the author of the project, and the
  # project create event will be displayed in user activities
  shared_let(:project) { User.execute_as(user) { create(:project, members: { user => role }) } }

  let(:admin) { create(:admin) }

  let(:instance) { described_class.new(user, options) }
  let(:options) { {} }

  it "does not find budgets in its event_types" do
    expect(instance.event_types)
      .not_to include("budgets")
  end

  describe "#events" do
    let(:event_user) { user }
    let(:work_package) { create(:work_package, project:, author: event_user) }
    let(:forum) { create(:forum, project:) }
    let(:message) { create(:message, forum:, author: event_user) }
    let(:news) { create(:news, project:, author: event_user) }
    let(:time_entry) { create(:time_entry, project:, entity: work_package, user: event_user) }
    let(:repository) { create(:repository_subversion, project:) }
    let(:changeset) { create(:changeset, committer: event_user.login, repository:) }
    let(:wiki) { create(:wiki, project:) }
    let(:wiki_page) { create(:wiki_page, wiki:, author: event_user, text: "some text") }
    let(:internal_note) do
      create(:work_package_journal,
             journable: work_package,
             user: admin,
             notes: "Internal comment",
             internal: true,
             version: 2,
             data: build(:journal_work_package_journal,
                         subject: work_package.subject,
                         status_id: work_package.status_id,
                         type_id: work_package.type_id,
                         project_id: work_package.project_id))
    end

    subject(:event_journables) { instance.events(from: 30.days.ago, to: 1.day.from_now).map { it.journal.journable } }

    def activities_of_types(*klasses)
      activities.select do |activity|
        klasses.any? do |klass|
          activity.is_a?(klass)
        end
      end
    end

    shared_examples "specifying scope" do
      context "without scope set" do
        it "finds events of all types" do
          expect(event_journables)
            .to match_array(activities)
        end
      end

      context "with scope :all" do
        before { options[:scope] = :all }

        it "finds events of all types" do
          expect(event_journables)
            .to match_array(activities)
        end
      end

      context "with scope :default" do
        before { options[:scope] = :default }

        it "finds events that are registered to be shown by default" do
          expect(event_journables)
            .to match_array(activities_of_types(WorkPackage, Changeset))
        end
      end

      context "with scope of event types" do
        before { options[:scope] = %w[time_entries messages project_details] }

        it "finds only events matching the scope" do
          expect(event_journables)
            .to match_array(activities_of_types(Message, TimeEntry, Project))
        end
      end
    end

    context "for global activities" do
      let!(:activities) { [project, work_package, message, news, time_entry, changeset, wiki_page] }

      it_behaves_like "specifying scope"

      context "if lacking permissions" do
        before do
          role.role_permissions.destroy_all
        end

        it "finds only events for which permissions are satisfied" do
          # project details, news and message only require the user to be member
          expect(event_journables)
            .to contain_exactly(project, message, news)
        end
      end

      context "if project has activity disabled" do
        before do
          project.enabled_module_names -= ["activity"]
        end

        it "finds no events" do
          expect(event_journables)
            .to be_empty
        end
      end

      context "if user cannot see internal journals" do
        before do
          role.role_permissions
            .find_by(permission: "view_internal_comments")
            .destroy

          # reload otherwise permissions don't update
          event_user.reload

          # make sure internal_note is created
          internal_note
        end

        it "does not find events with internal journals" do
          expect(instance.events.map(&:journal).select(&:internal)).to be_empty
        end
      end

      context "if user can see internal journals" do
        before do
          # make sure internal_note is created
          internal_note
        end

        it "finds events with internal journals" do
          expect(instance.events.map(&:journal).select(&:internal)).to include(internal_note)
        end
      end
    end

    context "for activities in a project" do
      let(:options) { { project: } }
      let!(:activities) { [project, work_package, message, news, time_entry, changeset, wiki_page] }

      it_behaves_like "specifying scope"

      context "if lacking permissions" do
        before do
          role
            .role_permissions
            # n.b. public permissions are now stored in the database just like others, so to keep the tests like they
            # are we need to filter them out here
            .reject { |permission| OpenProject::AccessControl.permission(permission.permission.to_sym).public? }
            .each(&:destroy)
        end

        it "finds only events for which permissions are satisfied" do
          # project details, news and message only require the user to be member
          expect(event_journables)
            .to contain_exactly(project, message, news)
        end
      end

      context "if project has activity disabled" do
        before do
          project.enabled_module_names -= ["activity"]
        end

        it "finds no events" do
          expect(event_journables)
            .to be_empty
        end
      end

      context "if user cannot see internal journals" do
        before do
          role.role_permissions
            .find_by(permission: "view_internal_comments")
            .destroy

          # reload otherwise permissions don't update
          event_user.reload

          # make sure internal_note is created
          internal_note
        end

        it "does not find events with internal journals" do
          expect(instance.events.map(&:journal).select(&:internal)).to be_empty
        end
      end

      context "if user can see internal journals" do
        before do
          # make sure internal_note is created
          internal_note
        end

        it "finds events with internal journals" do
          expect(instance.events.map(&:journal).select(&:internal)).to include(internal_note)
        end
      end
    end

    context "for activities in a subproject" do
      shared_let(:subproject) do
        create(:project, parent: project).tap do
          project.reload
        end
      end

      let(:options) { { project:, with_subprojects: 1 } }
      let(:subproject_news) { create(:news, project: subproject) }
      let(:subproject_work_package) { create(:work_package, project: subproject, author: event_user) }
      let(:subproject_member_permissions) { permissions }

      let!(:subproject_member) do
        create(:member,
               user:,
               project: subproject,
               roles: [create(:project_role, permissions: subproject_member_permissions)])
      end
      let!(:activities) { [project, subproject, news, subproject_news, work_package, subproject_work_package] }

      it_behaves_like "specifying scope"

      context "if the subproject has activity disabled" do
        before do
          subproject.enabled_module_names -= ["activity"]
        end

        it "lacks events from subproject" do
          expect(event_journables)
            .to contain_exactly(project, news, work_package)
        end
      end

      context "if not member of the subproject" do
        let!(:subproject_member) { nil }

        it "lacks events from subproject" do
          expect(event_journables)
            .to contain_exactly(project, news, work_package)
        end
      end

      context "if lacking permissions for the subproject" do
        let(:subproject_member_permissions) { [] }

        it "finds only events for which permissions are satisfied" do
          # project details and news only require the user to be member
          expect(event_journables)
            .to contain_exactly(project, subproject, news, subproject_news, work_package)
        end
      end

      context "if excluding subprojects" do
        let(:options) { { project:, with_subprojects: nil } }

        it "lacks events from subproject" do
          expect(event_journables)
            .to contain_exactly(project, news, work_package)
        end
      end
    end

    context "for activities of a user" do
      let(:options) { { author: user } }

      let!(:activities) do
        # Login to have all the journals created as the user
        login_as(user)
        [project, work_package, message, news, time_entry, changeset, wiki_page]
      end

      it_behaves_like "specifying scope"

      context "for a different user" do
        let(:other_user) { create(:user) }
        let(:options) { { author: other_user } }

        it "does not return the events made by the non queried for user" do
          expect(event_journables)
            .to be_empty
        end
      end

      context "if project has activity disabled" do
        before do
          project.enabled_module_names -= ["activity"]
        end

        it "finds no events" do
          expect(event_journables)
            .to be_empty
        end
      end

      context "if lacking permissions" do
        before do
          role.role_permissions.destroy_all
        end

        it "finds only events for which permissions are satisfied" do
          # project details, news and message only require the user to be member
          expect(event_journables)
            .to contain_exactly(project, message, news)
        end
      end
    end
  end
end
