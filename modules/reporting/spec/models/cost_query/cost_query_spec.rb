#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../../spec_helper'

describe User, "#destroy", type: :model do
  let(:substitute_user) { DeletedUser.first }
  let(:private_query) { FactoryBot.create(:private_cost_query) }
  let(:public_query) { FactoryBot.create(:public_cost_query) }
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }

  describe "WHEN the user has saved private cost queries" do

    before do
      private_query.user.destroy
    end

    it { expect(CostQuery.find_by_id(private_query.id)).to eq(nil) }
  end

  describe "WHEN the user has saved public cost queries" do
    before do
      public_query.user.destroy
    end

    it { expect(CostQuery.find_by_id(public_query.id)).to eq(public_query) }
    it { expect(public_query.reload.user_id).to eq(substitute_user.id) }
  end

  shared_examples_for "public query" do
    let(:filter_symbol) { filter.to_s.demodulize.underscore.to_sym }

    describe "WHEN the filter has the deleted user as it's value" do
      before do
        public_query.filter(filter_symbol, values: [user.id.to_s], operator: "=")
        public_query.save!

        user.destroy
      end

      it { expect(CostQuery.find_by_id(public_query.id).deserialize.filters.any?{ |f| f.is_a?(filter) }).to be_falsey }
    end

    describe "WHEN the filter has another user as it's value" do
      before do
        public_query.filter(filter_symbol, values: [user2.id.to_s], operator: "=")
        public_query.save!

        user.destroy
      end

      it { expect(CostQuery.find_by_id(public_query.id).deserialize.filters.any?{ |f| f.is_a?(filter) }).to be_truthy }
      it { expect(CostQuery.find_by_id(public_query.id).deserialize.filters.detect{ |f| f.is_a?(filter) }.values).to eq([user2.id.to_s]) }
    end

    describe "WHEN the filter has the deleted user and another user as it's value" do
      before do
        public_query.filter(filter_symbol, values: [user.id.to_s, user2.id.to_s], operator: "=")
        public_query.save!

        user.destroy
      end

      it { expect(CostQuery.find_by_id(public_query.id).deserialize.filters.any?{ |f| f.is_a?(filter) }).to be_truthy }
      it { expect(CostQuery.find_by_id(public_query.id).deserialize.filters.detect{ |f| f.is_a?(filter) }.values).to eq([user2.id.to_s]) }
    end
  end

  describe "WHEN someone has saved a public cost query
            WHEN the query has a user_id filter" do
    let(:filter) { CostQuery::Filter::UserId }

    it_should_behave_like "public query"
  end

  describe "WHEN someone has saved a public cost query
            WHEN the query has a author_id filter" do
    let(:filter) { CostQuery::Filter::AuthorId }

    it_should_behave_like "public query"
  end

  describe "WHEN someone has saved a public cost query
            WHEN the query has a assigned_to_id filter" do
    let(:filter) { CostQuery::Filter::AssignedToId }

    it_should_behave_like "public query"
  end
end
