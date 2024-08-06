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

RSpec.describe Activities::Fetcher, "integration" do
  shared_let(:user) { create(:user) }
  shared_let(:permissions) { %i[view_work_packages view_time_entries view_changesets view_wiki_edits] }
  shared_let(:role) { create(:project_role, permissions:) }
  # execute as user so that the user is the author of the project, and the
  # project create event will be displayed in user activities
  shared_let(:project) { User.execute_as(user) { create(:project, members: { user => role }) } }

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
    let(:time_entry) { create(:time_entry, project:, work_package:, user: event_user) }
    let(:repository) { create(:repository_subversion, project:) }
    let(:changeset) { create(:changeset, committer: event_user.login, repository:) }
    let(:wiki) { create(:wiki, project:) }
    let(:wiki_page) do
      create(:wiki_page, wiki:, author: event_user, text: "some text")
    end

    subject { instance.events(from: 30.days.ago, to: 1.day.from_now) }

    context "for global activities" do
      let!(:activities) { [project, work_package, message, news, time_entry, changeset, wiki_page] }

      it "finds events of all types" do
        expect(subject.map(&:journable_id))
          .to match_array(activities.map(&:id))
      end

      context "if lacking permissions" do
        before do
          role.role_permissions.destroy_all
        end

        it "finds only events for which permissions are satisfied" do
          # project attributes, news and message only require the user to be member
          expect(subject.map(&:journable_id))
            .to contain_exactly(project.id, message.id, news.id)
        end
      end

      context "if project has activity disabled" do
        before do
          project.enabled_module_names = project.enabled_module_names - ["activity"]
        end

        it "finds no events" do
          expect(subject.map(&:journable_id))
            .to be_empty
        end
      end

      context "if restricting the scope" do
        before do
          options[:scope] = %w(time_entries messages)
        end

        it "finds only events matching the scope" do
          expect(subject.map(&:journable_id))
            .to contain_exactly(message.id, time_entry.id)
        end
      end
    end

    context "for activities in a project" do
      let(:options) { { project: } }
      let!(:activities) { [project, work_package, message, news, time_entry, changeset, wiki_page] }

      it "finds events of all types" do
        expect(subject.map(&:journable_id))
          .to match_array(activities.map(&:id))
      end

      context "if lacking permissions" do
        before do
          role
          .role_permissions
          # n.b. public permissions are now stored in the database just like others, so to keep the tests like they are
          # we need to filter them out here
          .reject { |permission| OpenProject::AccessControl.permission(permission.permission.to_sym).public? }
          .map(&:destroy)
        end

        it "finds only events for which permissions are satisfied" do
          # project attributes, news and message only require the user to be member
          expect(subject.map(&:journable_id))
            .to contain_exactly(project.id, message.id, news.id)
        end
      end

      context "if project has activity disabled" do
        before do
          project.enabled_module_names = project.enabled_module_names - ["activity"]
        end

        it "finds no events" do
          expect(subject.map(&:journable_id))
            .to be_empty
        end
      end

      context "if restricting the scope" do
        before do
          options[:scope] = %w(time_entries messages)
        end

        it "finds only events matching the scope" do
          expect(subject.map(&:journable_id))
            .to contain_exactly(message.id, time_entry.id)
        end
      end
    end

    context "for activities in a subproject" do
      shared_let(:subproject) do
        create(:project, parent: project).tap do
          project.reload
        end
      end
      let(:subproject_news) { create(:news, project: subproject) }
      let(:subproject_work_package) { create(:work_package, project: subproject, author: event_user) }
      let(:subproject_member) do
        create(:member,
               user:,
               project: subproject,
               roles: [create(:project_role, permissions:)])
      end

      let!(:activities) { [project, subproject, news, subproject_news, work_package, subproject_work_package] }

      context "if including subprojects" do
        before do
          subproject_member
        end

        let(:options) { { project:, with_subprojects: 1 } }

        it "finds events in the subproject" do
          expect(subject.map(&:journable_id))
            .to match_array(activities.map(&:id))
        end
      end

      context "if the subproject has activity disabled" do
        before do
          subproject.enabled_module_names -= ["activity"]
        end

        it "lacks events from subproject" do
          expect(subject.map(&:journable_id))
            .to contain_exactly(project.id, news.id, work_package.id)
        end
      end

      context "if not member of the subproject" do
        let(:options) { { project:, with_subprojects: 1 } }

        it "lacks events from subproject" do
          expect(subject.map(&:journable_id))
            .to contain_exactly(project.id, news.id, work_package.id)
        end
      end

      context "if lacking permissions for the subproject" do
        let(:options) { { project:, with_subprojects: 1 } }
        let!(:subproject_member) do
          create(:member,
                 user:,
                 project: subproject,
                 roles: [create(:project_role, permissions: [])])
        end

        it "finds only events for which permissions are satisfied" do
          # project attributes and news only require the user to be member
          expect(subject.map(&:journable_id))
            .to contain_exactly(project.id, subproject.id, news.id, subproject_news.id, work_package.id)
          expect(subject.filter { |e| e.event_type.starts_with?("work_package") }.map(&:journable_id))
            .not_to include(subproject_work_package.id)
        end
      end

      context "if excluding subprojects" do
        before do
          subproject_member
        end

        let(:options) { { project:, with_subprojects: nil } }

        it "lacks events from subproject" do
          expect(subject.map(&:journable_id))
            .to contain_exactly(project.id, news.id, work_package.id)
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

      it "finds events of all types" do
        expect(subject.map(&:journable_id))
          .to match_array(activities.map(&:id))
      end

      context "for a different user" do
        let(:other_user) { create(:user) }
        let(:options) { { author: other_user } }

        it "does not return the events made by the non queried for user" do
          expect(subject.map(&:journable_id))
            .to be_empty
        end
      end

      context "if project has activity disabled" do
        before do
          project.enabled_module_names = project.enabled_module_names - ["activity"]
        end

        it "finds no events" do
          expect(subject.map(&:journable_id))
            .to be_empty
        end
      end

      context "if lacking permissions" do
        before do
          role.role_permissions.destroy_all
        end

        it "finds only events for which permissions are satisfied" do
          # project attributes, news and message only require the user to be member
          expect(subject.map(&:journable_id))
            .to contain_exactly(project.id, message.id, news.id)
        end
      end

      context "if restricting the scope" do
        before do
          options[:scope] = %w(time_entries messages)
        end

        it "finds only events matching the scope" do
          expect(subject.map(&:journable_id))
            .to contain_exactly(message.id, time_entry.id)
        end
      end
    end
  end
end
