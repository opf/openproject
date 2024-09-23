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

RSpec.describe Principals::DeleteJob, type: :model do
  subject(:job) { described_class.perform_now(principal) }

  shared_let(:project) { create(:project) }

  shared_let(:deleted_user) do
    create(:deleted_user)
  end
  let(:principal) do
    create(:user)
  end
  let(:member) do
    create(:member,
           principal:,
           project:,
           roles: [role])
  end

  shared_let(:role) do
    create(:project_role, permissions: %i[view_work_packages])
  end

  describe "#perform" do
    # These are the only tests that include testing
    # the ReplaceReferencesService. Most of the tests for this
    # Service are handled within the matching spec file.
    shared_examples_for "work_package handling" do
      let(:work_package) do
        create(:work_package,
               assigned_to: principal,
               responsible: principal)
      end

      before do
        work_package
        job
      end

      it "resets assigned to to the deleted user" do
        expect(work_package.reload.assigned_to)
          .to eql(deleted_user)
      end

      it "resets assigned to in all journals to the deleted user" do
        expect(Journal::WorkPackageJournal.pluck(:assigned_to_id))
          .to eql([deleted_user.id])
      end

      it "resets responsible to to the deleted user" do
        expect(work_package.reload.responsible)
          .to eql(deleted_user)
      end

      it "resets responsible to in all journals to the deleted user" do
        expect(Journal::WorkPackageJournal.pluck(:responsible_id))
          .to eql([deleted_user.id])
      end
    end

    shared_examples_for "labor_budget_item handling" do
      let(:item) { build(:labor_budget_item, user: principal) }

      before do
        item.save!

        job
      end

      it { expect(LaborBudgetItem.find_by(id: item.id)).to eq(item) }
      it { expect(item.user_id).to eq(principal.id) }
    end

    shared_examples_for "cost_entry handling" do
      let(:work_package) { create(:work_package) }
      let(:entry) do
        create(:cost_entry,
               user: principal,
               project: work_package.project,
               units: 100.0,
               spent_on: Time.zone.today,
               work_package:,
               comments: "")
      end

      before do
        create(:member,
               project: work_package.project,
               user: principal,
               roles: [build(:project_role)])
        entry

        job

        entry.reload
      end

      it { expect(entry.user_id).to eq(deleted_user.id) }
    end

    shared_examples_for "member handling" do
      before do
        member

        job
      end

      it "removes that member" do
        expect(Member.find_by(id: member.id)).to be_nil
      end

      it "leaves the role" do
        expect(Role.find_by(id: role.id)).to eq(role)
      end

      it "leaves the project" do
        expect(Project.find_by(id: project.id)).to eq(project)
      end
    end

    shared_examples_for "work package member handling" do
      let(:work_package) { create(:work_package, project:) }

      let(:work_package_member) do
        create(:work_package_member,
               principal:,
               project:,
               work_package:,
               roles: [role])
      end

      before do
        work_package_member

        job
      end

      it "removes that work package member" do
        expect(Member.find_by(id: work_package_member.id)).to be_nil
      end

      it "leaves the role" do
        expect(Role.find_by(id: role.id)).to eq(role)
      end

      it "leaves the work_package" do
        expect(WorkPackage.find_by(id: work_package.id)).to eq(work_package)
      end

      it "leaves the project" do
        expect(Project.find_by(id: project.id)).to eq(project)
      end
    end

    shared_examples_for "hourly_rate handling" do
      let(:hourly_rate) do
        build(:hourly_rate,
              user: principal,
              project:)
      end

      before do
        hourly_rate.save!
        job
      end

      it { expect(HourlyRate.find_by(id: hourly_rate.id)).to eq(hourly_rate) }
      it { expect(hourly_rate.reload.user_id).to eq(principal.id) }
    end

    shared_examples_for "watcher handling" do
      let(:watched) { create(:news, project:) }
      let(:watch) do
        Watcher.create(user: principal,
                       watchable: watched)
      end

      before do
        member
        watch

        job
      end

      it { expect(Watcher.find_by(id: watch.id)).to be_nil }
    end

    shared_examples_for "rss token handling" do
      let(:token) do
        Token::RSS.new(user: principal, value: "loremipsum")
      end

      before do
        token.save!

        job
      end

      it { expect(Token::RSS.find_by(id: token.id)).to be_nil }
    end

    shared_examples_for "notification handling" do
      let(:notification) do
        create(:notification, recipient: principal)
      end

      before do
        notification

        job
      end

      it { expect(Notification.find_by(id: notification.id)).to be_nil }
    end

    shared_examples_for "private query handling" do
      let!(:query) do
        create(:private_query, user: principal, views: create_list(:view_work_packages_table, 1))
      end

      before do
        job
      end

      it { expect(Query.find_by(id: query.id)).to be_nil }
    end

    shared_examples_for "backup token handling" do
      let!(:backup_token) do
        create(:backup_token, user: principal)
      end

      let!(:invitation_token) do
        create(:invitation_token, user: principal)
      end

      before do
        job
      end

      it { expect(Token::Base.where(user_id: principal.id)).to be_empty }
    end

    shared_examples_for "issue category handling" do
      let(:category) do
        create(:category,
               assigned_to: principal,
               project:)
      end

      before do
        member
        category
        job
      end

      it "does not remove the category" do
        expect(Category.find_by(id: category.id)).to eq(category)
      end

      it "removes the assigned_to association to the principal" do
        expect(category.reload.assigned_to).to be_nil
      end
    end

    shared_examples_for "removes the principal" do
      it "deletes the principal" do
        job

        expect(Principal.find_by(id: principal.id))
          .to be_nil
      end
    end

    shared_examples_for "private cost_query handling" do
      let!(:query) { create(:private_cost_query, user: principal) }

      it "removes the query" do
        job

        expect(CostQuery.find_by(id: query.id)).to be_nil
      end
    end

    shared_examples_for "project query handling" do
      let!(:query) { create(:project_query, user: principal) }

      it "removes the query" do
        job

        expect(ProjectQuery.find_by(id: query.id)).to be_nil
      end
    end

    shared_examples_for "public cost_query handling" do
      let!(:query) { create(:public_cost_query, user: principal) }

      before do
        query

        job
      end

      it "leaves the query" do
        expect(CostQuery.find_by(id: query.id)).to eq(query)
      end

      it "rewrites the user reference" do
        expect(query.reload.user).to eq(deleted_user)
      end
    end

    shared_examples_for "cost_query handling" do
      let(:query) { create(:cost_query) }
      let(:other_user) { create(:user) }

      shared_examples_for "public query rewriting" do
        let(:filter_symbol) { filter.to_s.demodulize.underscore.to_sym }

        describe "with the filter has the deleted user as it's value" do
          before do
            query.filter(filter_symbol, values: [principal.id.to_s], operator: "=")
            query.save!

            job
          end

          it "removes the filter" do
            expect(CostQuery.find_by(id: query.id).deserialize.filters)
              .not_to(be_any { |f| f.is_a?(filter) })
          end
        end

        describe "with the filter has another user as it's value" do
          before do
            query.filter(filter_symbol, values: [other_user.id.to_s], operator: "=")
            query.save!

            job
          end

          it "keeps the filter" do
            expect(CostQuery.find_by(id: query.id).deserialize.filters)
              .to(be_any { |f| f.is_a?(filter) })
          end

          it "does not alter the filter values" do
            expect(CostQuery.find_by(id: query.id).deserialize.filters.detect do |f|
              f.is_a?(filter)
            end.values).to eq([other_user.id.to_s])
          end
        end

        describe "with the filter has the deleted user and another user as it's value" do
          before do
            query.filter(filter_symbol, values: [principal.id.to_s, other_user.id.to_s], operator: "=")
            query.save!

            job
          end

          it "keeps the filter" do
            expect(CostQuery.find_by(id: query.id).deserialize.filters)
              .to(be_any { |f| f.is_a?(filter) })
          end

          it "removes only the deleted user" do
            expect(CostQuery.find_by(id: query.id).deserialize.filters.detect do |f|
              f.is_a?(filter)
            end.values).to eq([other_user.id.to_s])
          end
        end
      end

      describe "with the query has a user_id filter" do
        let(:filter) { CostQuery::Filter::UserId }

        it_behaves_like "public query rewriting"
      end

      describe "with the query has a author_id filter" do
        let(:filter) { CostQuery::Filter::AuthorId }

        it_behaves_like "public query rewriting"
      end

      describe "with the query has a assigned_to_id filter" do
        let(:filter) { CostQuery::Filter::AssignedToId }

        it_behaves_like "public query rewriting"
      end

      describe "with the query has an responsible_id filter" do
        let(:filter) { CostQuery::Filter::ResponsibleId }

        it_behaves_like "public query rewriting"
      end
    end

    shared_examples_for "mention rewriting" do
      let(:text) do
        <<~TEXT
          <mention class="mention"
                   data-id="#{principal.id}"
                   data-type="user"
                   data-text="@#{principal.name}">
                   @#{principal.name}
          </mention>
        TEXT
      end
      let(:expected_text) do
        <<~TEXT.squish
          <mention class="mention"
                   data-id="#{deleted_user.id}"
                   data-type="user"
                   data-text="@#{deleted_user.name}">@#{deleted_user.name}</mention>
        TEXT
      end
      let!(:work_package) { create(:work_package, description: text) }

      before do
        job
      end

      it "rewrites the mentioning in the text" do
        expect(work_package.reload.description)
          .to include expected_text
      end
    end

    context "with a user" do
      it_behaves_like "removes the principal"
      it_behaves_like "work_package handling"
      it_behaves_like "labor_budget_item handling"
      it_behaves_like "cost_entry handling"
      it_behaves_like "hourly_rate handling"
      it_behaves_like "member handling"
      it_behaves_like "watcher handling"
      it_behaves_like "rss token handling"
      it_behaves_like "backup token handling"
      it_behaves_like "notification handling"
      it_behaves_like "private query handling"
      it_behaves_like "issue category handling"
      it_behaves_like "private cost_query handling"
      it_behaves_like "public cost_query handling"
      it_behaves_like "cost_query handling"
      it_behaves_like "project query handling"
      it_behaves_like "mention rewriting"
    end

    context "with a group" do
      let(:principal) { create(:group, members: group_members) }
      let(:group_members) { [] }

      it_behaves_like "removes the principal"
      it_behaves_like "work_package handling"
      it_behaves_like "member handling"
      it_behaves_like "mention rewriting"

      context "with user only in project through group" do
        let(:user) do
          create(:user)
        end
        let(:group_members) { [user] }
        let(:watched) { create(:news, project:) }
        let(:watch) do
          Watcher.create(user:,
                         watchable: watched)
        end

        it "removes the watcher" do
          job

          expect(watched.watchers.reload).to be_empty
        end
      end
    end

    context "with a placeholder user" do
      let(:principal) { create(:placeholder_user) }

      it_behaves_like "removes the principal"
      it_behaves_like "work_package handling"
    end
  end
end
