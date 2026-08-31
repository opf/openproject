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
require_relative "replace_references_context"

RSpec.describe Principals::ReplaceReferencesService, "#call", type: :model do
  subject(:service_call) { instance.call(from: principal, to: to_principal) }

  shared_let(:other_user) { create(:user) }
  shared_let(:user) { create(:user) }
  shared_let(:to_principal) { create(:user) }

  let(:instance) do
    described_class.new
  end

  context "with a user" do
    let(:principal) { user }

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    context "with a Journal" do
      let!(:journal) do
        create(:work_package_journal,
               user_id:)
      end

      context "with the replaced user" do
        let(:user_id) { principal.id }

        before do
          service_call
          journal.reload
        end

        it "replaces user_id" do
          expect(journal.user_id)
            .to eql to_principal.id
        end
      end

      context "with a different user" do
        let(:user_id) { other_user.id }

        before do
          service_call
          journal.reload
        end

        it "replaces user_id" do
          expect(journal.user_id)
            .to eql other_user.id
        end
      end
    end

    context "with Attachment" do
      it_behaves_like "rewritten record",
                      Attachment,
                      :author_id

      it_behaves_like "rewritten record",
                      Journal::AttachmentJournal,
                      :author_id do
        let(:attributes) do
          {
            filename: "'abc.txt'",
            disk_filename: "'abc.txt'",
            filesize: 123,
            digest: "'qwerty'",
            downloads: 5
          }
        end
      end
    end

    context "with Comment" do
      shared_let(:news) { create(:news) }

      it_behaves_like "rewritten record",
                      Comment,
                      :author_id do
        let(:attributes) do
          {
            commented_id: news.id,
            commented_type: "'Comment'"
          }
        end
      end
    end

    context "with CustomValue" do
      shared_let(:version) { create(:version) }

      it_behaves_like "rewritten record",
                      CustomValue,
                      :value,
                      String do
        let(:user_cf) { create(:user_wp_custom_field) }
        let(:attributes) do
          {
            custom_field_id: user_cf.id,
            customized_id: version.id,
            customized_type: "'Version'"
          }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::CustomizableJournal,
                      :value,
                      String do
        let(:user_cf) { create(:user_wp_custom_field) }
        let(:attributes) do
          {
            journal_id: 1,
            custom_field_id: user_cf.id
          }
        end
      end
    end

    context "with Changeset" do
      it_behaves_like "rewritten record",
                      Changeset,
                      :user_id do
        let(:attributes) do
          { repository_id: 1,
            revision: 1,
            committed_on: "date '2012-02-02'" }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::ChangesetJournal,
                      :user_id do
        let(:attributes) do
          { repository_id: 1,
            revision: 1,
            committed_on: "date '2012-02-02'" }
        end
      end
    end

    context "with Message" do
      it_behaves_like "rewritten record",
                      Message,
                      :author_id do
        let(:attributes) do
          {
            forum_id: 1,
            subject: "'abc'"
          }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::MessageJournal,
                      :author_id do
        let(:attributes) do
          {
            forum_id: 1,
            subject: "'abc'"
          }
        end
      end
    end

    context "with News" do
      it_behaves_like "rewritten record",
                      News,
                      :author_id

      it_behaves_like "rewritten record",
                      Journal::NewsJournal,
                      :author_id do
        let(:attributes) do
          {
            title: "'abc'",
            comments_count: 5
          }
        end
      end
    end

    context "with WikiPage" do
      it_behaves_like "rewritten record",
                      WikiPage,
                      :author_id do
        let(:attributes) do
          {
            wiki_id: 1,
            title: "'Lorem'",
            slug: "'lorem'",
            updated_at: "'#{DateTime.current}'",
            lock_version: 5
          }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::WikiPageJournal,
                      :author_id
    end

    context "with WorkPackage" do
      shared_let(:project) { create(:project) }
      shared_let(:type) { create(:type) }
      shared_let(:status) { create(:status) }
      shared_let(:priority) { create(:priority) }
      shared_let(:author) { create(:user) }

      let(:attributes) do
        {
          project_id: project.id,
          type_id: type.id,
          status_id: status.id,
          priority_id: priority.id,
          author_id: author.id,
          subject: "'abc'",
          done_ratio: 0
        }
      end

      it_behaves_like "rewritten record",
                      WorkPackage,
                      :author_id

      it_behaves_like "rewritten record",
                      WorkPackage,
                      :assigned_to_id

      it_behaves_like "rewritten record",
                      WorkPackage,
                      :responsible_id

      it_behaves_like "rewritten record",
                      Journal::WorkPackageJournal,
                      :assigned_to_id do
        let(:attributes) do
          {
            # This part is not related to the test but the columns are non nullable.
            ignore_non_working_days: false,
            subject: "'abc'",
            done_ratio: 5,
            # End non relevant.
            project_id: project.id,
            type_id: type.id,
            status_id: status.id,
            priority_id: priority.id,
            author_id: author.id
          }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::WorkPackageJournal,
                      :responsible_id do
        let(:attributes) do
          {
            # This part is not related to the test but the columns are non nullable.
            ignore_non_working_days: false,
            subject: "'abc'",
            done_ratio: 5,
            # End non relevant.
            project_id: project.id,
            type_id: type.id,
            status_id: status.id,
            priority_id: priority.id,
            author_id: author.id
          }
        end
      end
    end

    context "with TimeEntry" do
      it_behaves_like "rewritten record",
                      TimeEntry,
                      :user_id do
        let(:attributes) do
          { project_id: 1,
            hours: 5,
            activity_id: 1,
            spent_on: "date '2012-02-02'",
            tyear: 2021,
            tmonth: 12,
            tweek: 5,
            logged_by_id: principal.id }
        end
      end

      it_behaves_like "rewritten record",
                      TimeEntry,
                      :logged_by_id do
        let(:attributes) do
          { project_id: 1,
            hours: 5,
            activity_id: 1,
            spent_on: "date '2012-02-02'",
            tyear: 2021,
            tmonth: 12,
            tweek: 5,
            user_id: principal.id }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::TimeEntryJournal,
                      :user_id do
        let(:attributes) do
          { project_id: 1,
            hours: 5,
            activity_id: 1,
            spent_on: "date '2012-02-02'",
            tyear: 2021,
            tmonth: 12,
            tweek: 5,
            logged_by_id: principal.id }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::TimeEntryJournal,
                      :logged_by_id do
        let(:attributes) do
          { project_id: 1,
            hours: 5,
            activity_id: 1,
            spent_on: "date '2012-02-02'",
            tyear: 2021,
            tmonth: 12,
            tweek: 5,
            user_id: principal.id }
        end
      end
    end

    context "with Budget" do
      it_behaves_like "rewritten record",
                      Budget,
                      :author_id do
        let(:attributes) do
          { project_id: 1,
            subject: "'abc'",
            description: "'cde'",
            fixed_date: "date '2012-02-02'" }
        end
      end

      it_behaves_like "rewritten record",
                      Journal::BudgetJournal,
                      :author_id do
        let(:attributes) do
          { project_id: 1,
            subject: "'abc'",
            fixed_date: "date '2012-02-02'" }
        end
      end
    end

    context "with Query" do
      it_behaves_like "rewritten record",
                      Query,
                      :user_id do
        let(:attributes) do
          {
            include_subprojects: true,
            name: "'abc'"
          }
        end
      end
    end

    context "with CostQuery" do
      let(:query) { create(:cost_query, user: principal) }

      it_behaves_like "rewritten record",
                      CostQuery,
                      :user_id do
        let(:attributes) do
          { name: "'abc'",
            serialized: "'cde'" }
        end
      end
    end

    context "with Notification actor" do
      let(:recipient) { create(:user) }

      it_behaves_like "rewritten record",
                      Notification,
                      :actor_id do
        let(:attributes) do
          {
            recipient_id: user.id,
            resource_id: 1234,
            resource_type: "'WorkPackage'"
          }
        end
      end
    end

    context "with OAuth application" do
      it_behaves_like "rewritten record",
                      Doorkeeper::Application,
                      :owner_id do
        let(:attributes) do
          {
            name: "'foo'",
            uid: "'bar'",
            secret: "'bar'",
            redirect_uri: "'urn:whatever'"
          }
        end
      end
    end
  end
end
