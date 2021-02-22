#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Principals::DeleteJob, type: :model do
  subject(:job) { described_class.perform_now(principal) }

  shared_let(:project) { FactoryBot.create(:project) }

  shared_let(:deleted_user) do
    FactoryBot.create(:deleted_user)
  end
  let(:principal) do
    FactoryBot.create(:user)
  end
  let(:member) do
    FactoryBot.create(:member,
                      principal: principal,
                      project: project,
                      roles: [role])
  end
  shared_let(:role) do
    FactoryBot.create(:role, permissions: %i[view_work_packages] )
  end

  describe '#perform' do
    # These are the only tests that include testing
    # the ReplaceReferencesService. Most of the tests for this
    # Service are handled within the matching spec file.
    shared_examples_for 'work_package handling' do
      let(:work_package) do
        FactoryBot.create(:work_package,
                          assigned_to: principal,
                          responsible: principal)
      end

      before do
        work_package
        job
      end

      it 'resets assigned to to the deleted user' do
        expect(work_package.reload.assigned_to)
          .to eql(deleted_user)
      end

      it 'resets assigned to in all journals to the deleted user' do
        expect(Journal::WorkPackageJournal.pluck(:assigned_to_id))
          .to eql([deleted_user.id])
      end

      it 'resets responsible to to the deleted user' do
        expect(work_package.reload.responsible)
          .to eql(deleted_user)
      end

      it 'resets responsible to in all journals to the deleted user' do
        expect(Journal::WorkPackageJournal.pluck(:responsible_id))
          .to eql([deleted_user.id])
      end
    end

    shared_examples_for 'labor_budget_item handling' do
      let(:item) { FactoryBot.build(:labor_budget_item, user: principal) }

      before do
        item.save!

        job
      end

      it { expect(LaborBudgetItem.find_by_id(item.id)).to eq(item) }
      it { expect(item.user_id).to eq(principal.id) }
    end

    shared_examples_for 'cost_entry handling' do
      let(:work_package) { FactoryBot.create(:work_package) }
      let(:entry) do
        FactoryBot.create(:cost_entry,
                          user: principal,
                          project: work_package.project,
                          units: 100.0,
                          spent_on: Date.today,
                          work_package: work_package,
                          comments: '')
      end

      before do
        FactoryBot.create(:member,
                          project: work_package.project,
                          user: principal,
                          roles: [FactoryBot.build(:role)])
        entry

        job

        entry.reload
      end

      it { expect(entry.user_id).to eq(principal.id) }
    end

    shared_examples_for 'member handling' do
      before do
        member

        job
      end

      it 'removes that member' do
        expect(Member.find_by(id: member.id)).to be_nil
      end

      it 'leaves the role' do
        expect(Role.find_by(id: role.id)).to eq(role)
      end

      it 'leaves the project' do
        expect(Project.find_by(id: project.id)).to eq(project)
      end
    end

    shared_examples_for 'hourly_rate handling' do
      let(:hourly_rate) do
        FactoryBot.build(:hourly_rate,
                         user: principal,
                         project: project)
      end

      before do
        hourly_rate.save!
        job
      end

      it { expect(HourlyRate.find_by_id(hourly_rate.id)).to eq(hourly_rate) }
      it { expect(hourly_rate.reload.user_id).to eq(principal.id) }
    end

    shared_examples_for 'watcher handling' do
      let(:watched) { FactoryBot.create(:news, project: project) }
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

    shared_examples_for 'token handling' do
      let(:token) do
        Token::RSS.new(user: principal, value: 'loremipsum')
      end

      before do
        token.save!

        job
      end

      it { expect(Token::RSS.find_by(id: token.id)).to be_nil }
    end

    shared_examples_for 'private query handling' do
      let!(:query) do
        FactoryBot.create(:private_query, user: principal)
      end

      before do
        job
      end

      it { expect(Query.find_by(id: query.id)).to be_nil }
    end

    shared_examples_for 'issue category handling' do
      let(:category) do
        FactoryBot.create(:category,
                          assigned_to: principal,
                          project: project)
      end

      before do
        member
        category
        job
      end

      it 'does not remove the category' do
        expect(Category.find_by(id: category.id)).to eq(category)
      end

      it 'removes the assigned_to association to the principal' do
        expect(category.reload.assigned_to).to be_nil
      end
    end

    shared_examples_for 'removes the principal' do
      it 'deletes the principal' do
        job

        expect(Principal.find_by(id: principal.id))
          .to be_nil
      end
    end

    shared_examples_for 'private cost_query handling' do
      let!(:query) { FactoryBot.create(:private_cost_query, user: principal) }

      it 'removes the query' do
        job

        expect(CostQuery.find_by_id(query.id)).to eq(nil)
      end
    end

    shared_examples_for 'public cost_query handling' do
      let!(:query) { FactoryBot.create(:public_cost_query, user: principal) }

      before do
        query

        job
      end

      it 'leaves the query' do
        expect(CostQuery.find_by_id(query.id)).to eq(query)
      end

      it 'rewrites the user reference' do
        expect(query.reload.user).to eq(deleted_user)
      end
    end

    shared_examples_for 'cost_query handling' do
      let(:query) { FactoryBot.create(:cost_query) }
      let(:other_user) { FactoryBot.create(:user) }

      shared_examples_for "public query rewriting" do
        let(:filter_symbol) { filter.to_s.demodulize.underscore.to_sym }

        describe "with the filter has the deleted user as it's value" do
          before do
            query.filter(filter_symbol, values: [principal.id.to_s], operator: "=")
            query.save!

            job
          end

          it 'removes the filter' do
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

          it 'keeps the filter' do
            expect(CostQuery.find_by(id: query.id).deserialize.filters)
              .to(be_any { |f| f.is_a?(filter) })
          end

          it 'does not alter the filter values' do
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

          it 'keeps the filter' do
            expect(CostQuery.find_by(id: query.id).deserialize.filters)
              .to(be_any { |f| f.is_a?(filter) })
          end

          it 'removes only the deleted user' do
            expect(CostQuery.find_by(id: query.id).deserialize.filters.detect do |f|
              f.is_a?(filter)
            end.values).to eq([other_user.id.to_s])
          end
        end
      end

      describe "with the query has a user_id filter" do
        let(:filter) { CostQuery::Filter::UserId }

        it_should_behave_like "public query rewriting"
      end

      describe "with the query has a author_id filter" do
        let(:filter) { CostQuery::Filter::AuthorId }

        it_should_behave_like "public query rewriting"
      end

      describe "with the query has a assigned_to_id filter" do
        let(:filter) { CostQuery::Filter::AssignedToId }

        it_should_behave_like "public query rewriting"
      end

      describe "with the query has an responsible_id filter" do
        let(:filter) { CostQuery::Filter::ResponsibleId }

        it_should_behave_like "public query rewriting"
      end
    end

    context 'with a user' do
      it_behaves_like 'removes the principal'
      it_behaves_like 'work_package handling'
      it_behaves_like 'labor_budget_item handling'
      it_behaves_like 'cost_entry handling'
      it_behaves_like 'hourly_rate handling'
      it_behaves_like 'member handling'
      it_behaves_like 'watcher handling'
      it_behaves_like 'token handling'
      it_behaves_like 'private query handling'
      it_behaves_like 'issue category handling'
      it_behaves_like 'private cost_query handling'
      it_behaves_like 'public cost_query handling'
      it_behaves_like 'cost_query handling'
    end

    context 'with a group' do
      let(:principal) { FactoryBot.create(:group, members: group_members) }
      let(:group_members) { [] }

      it_behaves_like 'removes the principal'
      it_behaves_like 'work_package handling'
      it_behaves_like 'member handling'

      context 'with user only in project through group' do
        let(:user) do
          FactoryBot.create(:user)
        end
        let(:group_members) { [user] }
        let(:watched) { FactoryBot.create(:news, project: project) }
        let(:watch) do
          Watcher.create(user: user,
                         watchable: watched)
        end

        it 'removes the watcher' do
          job

          expect(watched.watchers.reload).to be_empty
        end
      end
    end

    context 'with a placeholder user' do
      let(:principal) { FactoryBot.create(:placeholder_user) }

      it_behaves_like 'removes the principal'
      it_behaves_like 'work_package handling'
    end
  end
end
