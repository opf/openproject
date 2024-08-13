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

RSpec.describe Changeset do
  let(:email) { "bob@bobbit.org" }

  with_virtual_subversion_repository do
    let(:changeset) do
      build(:changeset,
            repository:,
            revision: "1",
            committer: email,
            comments: "Initial commit")
    end
  end

  shared_examples_for "valid changeset" do
    it { expect(changeset.revision).to eq("1") }

    it { expect(changeset.committer).to eq(email) }

    it { expect(changeset.comments).to eq("Initial commit") }

    describe "journal" do
      let(:journal) { changeset.journals.first }

      it { expect(journal.user).to eq(journal_user) }

      it { expect(journal.notes).to eq(changeset.comments) }
    end
  end

  describe "empty comment" do
    it "commentses empty" do
      changeset.comments = ""
      expect(changeset.save).to be true
      expect(changeset.comments).to eq ""

      if changeset.comments.respond_to?(:force_encoding)
        expect(changeset.comments.encoding.to_s).to eq("UTF-8")
      end
    end

    it "commentses nil" do
      changeset.comments = nil
      expect(changeset.save).to be true
      expect(changeset.comments).to eq ""

      if changeset.comments.respond_to?(:force_encoding)
        expect(changeset.comments.encoding.to_s).to eq("UTF-8")
      end
    end
  end

  describe "stripping commit" do
    let(:comment) { "This is a looooooooooooooong comment" + (((" " * 80) + "\n") * 5) }

    with_virtual_subversion_repository do
      let(:changeset) do
        build(:changeset,
              repository:,
              revision: "1",
              committer: email,
              comments: comment)
      end
    end

    it "fors changeset comments strip" do
      expect(changeset.save).to be true
      expect(comment).not_to eq changeset.comments
      expect(changeset.comments).to eq "This is a looooooooooooooong comment"
    end
  end

  describe "mapping" do
    let!(:user) { create(:user, login: "jsmith", mail: "jsmith@somenet.foo") }
    let!(:repository) { create(:repository_subversion) }

    it "supports manual user mapping with repository.committer_ids" do
      c = create(:changeset, repository:, committer: "foo")

      expect(c.user).to be_nil
      repository.committer_ids = { "foo" => user.id }
      expect(c.reload.user).to eq user

      # committer is now mapped
      c = create(:changeset, repository:, committer: "foo")
      expect(c.user).to eq user
    end

    it "maps user automatically when username matches" do
      c = create(:changeset, repository:, committer: user.login)
      expect(c.user).to eq user
    end

    it "maps user automatically when email matches" do
      c = create(:changeset, repository:, committer: "john <#{user.mail}>")

      expect(c.user).to eq user
    end
  end

  describe "#scan_comment_for_work_package_ids",
           with_settings: {
             commit_ref_keywords: "refs , references, IssueID",
             commit_fix_keywords: "fixes , closes",
             default_language: "en",
             work_package_done_ratio: "status"
           } do
    let!(:user) do
      create(:admin,
             login: "dlopper",
             member_with_roles: { repository.project => role })
    end
    let!(:open_status) { create(:status) }
    let!(:closed_status) { create(:closed_status, default_done_ratio: 90) }
    let!(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }

    let!(:other_work_package) { create(:work_package, status: open_status) }
    let!(:parent_work_package) { create(:work_package, subject: "Parent wp") }
    let!(:workflow) do
      create(:workflow,
             old_status: open_status,
             new_status: closed_status,
             role:,
             type: work_package.type)
    end
    let(:comments) { "Some fix made, fixes ##{work_package.id} and fixes ##{other_work_package.id}" }

    with_virtual_subversion_repository do
      let!(:work_package) do
        create(:work_package,
               project: repository.project,
               status: open_status,
               parent: parent_work_package,
               estimated_hours: 100)
      end
      let(:changeset) do
        create(:changeset,
               repository:,
               revision: "123",
               committer: user.login,
               comments:)
      end
    end

    before do
      # choosing a status to apply to fix issues
      allow(Setting).to receive(:commit_fix_status_id).and_return closed_status.id
    end

    describe "with any matching", with_settings: { commit_ref_keywords: "*" } do
      describe "reference with brackets" do
        let(:comments) { "[##{work_package.id}] Worked on this work_package" }

        it "references" do
          changeset.scan_comment_for_work_package_ids
          work_package.reload

          expect(work_package.changesets).to eq [changeset]
        end
      end

      describe "reference at line start" do
        let(:comments) { "##{work_package.id} Worked on this work_package" }

        it "references" do
          changeset.scan_comment_for_work_package_ids
          work_package.reload

          expect(work_package.changesets).to eq [changeset]
        end
      end
    end

    describe "non matching ref" do
      let(:comments) { "Some fix ignores ##{work_package.id}" }

      it "references the work package id" do
        changeset.scan_comment_for_work_package_ids
        work_package.reload

        expect(work_package.changesets).to eq []
      end
    end

    describe "with timelogs" do
      let!(:activity) { create(:activity, is_default: true) }

      before do
        repository.project.enabled_module_names += ["costs"]
        repository.project.save!
      end

      it "refs keywords any with timelog" do
        allow(Setting).to receive(:commit_ref_keywords).and_return "*"
        allow(Setting).to receive(:commit_logtime_enabled?).and_return true

        {
          "2" => 2.0,
          "2h" => 2.0,
          "2hours" => 2.0,
          "15m" => 0.25,
          "15min" => 0.25,
          "3h15" => 3.25,
          "2h15m" => 2.25,
          "2h15min" => 2.25,
          "2:15" => 2.25,
          "2.25" => 2.25,
          "1.25h" => 1.25,
          "0,75" => 0.75,
          "1,25h" => 1.25
        }.each do |syntax, expected_hours|
          c = build(:changeset,
                    repository:,
                    committed_on: 24.hours.ago,
                    commit_date: Date.yesterday,
                    comments: "Worked on this work_package ##{work_package.id} @#{syntax}",
                    revision: "520",
                    user:)

          expect { c.scan_comment_for_work_package_ids }
            .to change(TimeEntry, :count).by(1)

          expect(c.work_package_ids).to eq [work_package.id]

          time = TimeEntry.order(Arel.sql("id DESC")).first
          expect(work_package.id).to eq(time.work_package_id)
          expect(work_package.project_id).to eq(time.project_id)
          expect(user.id).to eq(time.user_id)

          expect(time.hours).to eq expected_hours
          expect(time.spent_on).to eq Date.yesterday

          expect(time.activity.is_default).to be true
          expect(time.comments).to include "r520"
        end
      end

      context "with a second work package" do
        let!(:work_package2) { create(:work_package, project: repository.project, status: open_status) }

        it "refs keywords closing with timelog" do
          allow(Setting).to receive(:commit_fix_status_id).and_return closed_status.id
          allow(Setting).to receive(:commit_ref_keywords).and_return "*"
          allow(Setting).to receive(:commit_fix_keywords).and_return "fixes , closes"
          allow(Setting).to receive(:commit_logtime_enabled?).and_return true

          c = build(:changeset,
                    repository:,
                    comments: "This is a comment. Fixes ##{work_package.id} @4.5, ##{work_package2.id} @1",
                    revision: "520",
                    user:)

          expect { c.scan_comment_for_work_package_ids }
            .to change(TimeEntry, :count).by(2)

          expect(c.work_package_ids).to contain_exactly(work_package.id, work_package2.id)

          work_package.reload
          work_package2.reload
          expect(work_package).to be_closed
          expect(work_package2).to be_closed

          times = TimeEntry.order(Arel.sql("id desc")).limit(2)
          expect(times.map(&:work_package_id)).to contain_exactly(work_package.id, work_package2.id)
        end
      end
    end

    it "references the work package id" do
      # make sure work package 1 is not already closed
      expect(work_package.status.is_closed?).to be false

      changeset.scan_comment_for_work_package_ids
      work_package.reload

      expect(work_package.changesets).to eq [changeset]

      expect(work_package.status).to eq closed_status
      expect(work_package.done_ratio).to eq 90
      expect(work_package.remaining_hours).to eq 10

      # journal updates
      journal = work_package.journals.last

      expect(journal.user).to eq user
      expect(journal.notes).to eq "Applied in changeset r123."

      # Expect other work package to be unchanged
      # due to other project
      other_work_package.reload
      expect(other_work_package.changesets).to eq []

      # Expect the parent to be updated
      parent_work_package.reload

      expect(parent_work_package.done_ratio).to eq 0
      expect(parent_work_package.derived_remaining_hours).to eq 10
      expect(parent_work_package.derived_done_ratio).to eq 90
    end

    describe "with work package in parent project" do
      let(:parent) { create(:project) }
      let!(:work_package) { create(:work_package, project: parent, status: open_status) }

      before do
        repository.project.parent = parent
        repository.project.save!
      end

      it "can reference it" do
        # make sure work package 1 is not already closed
        expect(work_package.status.is_closed?).to be false

        changeset.scan_comment_for_work_package_ids
        work_package.reload

        expect(work_package.changesets).to eq [changeset]

        # Expect other work package to be unchanged
        # due to other project
        other_work_package.reload
        expect(other_work_package.changesets).to eq []
      end
    end

    describe "with work package in sub project" do
      let(:sub) { create(:project) }
      let!(:work_package) { create(:work_package, project: sub, status: open_status) }

      before do
        sub.parent = repository.project
        sub.save!

        repository.project.reload
        sub.reload
      end

      it "can reference it" do
        # make sure work package 1 is not already closed
        expect(work_package.status.is_closed?).to be false

        changeset.scan_comment_for_work_package_ids
        work_package.reload

        expect(work_package.changesets).to eq [changeset]

        # Expect other work package to be unchanged
        # due to other project
        other_work_package.reload
        expect(other_work_package.changesets).to eq []
      end
    end
  end

  describe "assign_openproject user" do
    describe "w/o user" do
      before do
        changeset.save!
      end

      it_behaves_like "valid changeset" do
        let(:journal_user) { User.anonymous }
      end
    end

    describe "with user is committer" do
      let!(:committer) { create(:user, login: email) }

      before do
        changeset.save!
      end

      it_behaves_like "valid changeset" do
        let(:journal_user) { committer }
      end
    end

    describe "current user is not committer" do
      let(:current_user) { create(:user) }
      let!(:committer) { create(:user, login: email) }

      before do
        allow(User).to receive(:current).and_return current_user

        changeset.save!
      end

      it_behaves_like "valid changeset" do
        let(:journal_user) { committer }
      end
    end
  end
end
