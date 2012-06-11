require File.dirname(__FILE__) + '/../../spec_helper'

describe User, "#destroy" do
  let(:substitute_user) { DeletedUser.first }
  let(:private_query) { Factory.create(:private_cost_query) }
  let(:public_query) { Factory.create(:public_cost_query) }
  let(:user) { Factory.create(:user) }
  let(:user2) { Factory.create(:user) }

  describe "WHEN the user has saved private cost queries" do

    before do
      private_query.user.destroy
    end

    it { CostQuery.find_by_id(private_query.id).should == nil }
  end

  describe "WHEN the user has saved public cost queries" do
    before do
      public_query.user.destroy
    end

    it { CostQuery.find_by_id(public_query.id).should == public_query }
    it { public_query.reload.user_id.should == substitute_user.id }
  end

  shared_examples_for "public query" do
    let(:filter_symbol) { filter.to_s.demodulize.underscore.to_sym }

    describe "WHEN the filter has the deleted user as it's value" do
      before do
        public_query.filter(filter_symbol, :values => [user.id.to_s], :operator => "=")
        public_query.save!

        user.destroy
      end

      it { CostQuery.find_by_id(public_query.id).deserialize.filters.any?{ |f| f.is_a?(filter) }.should be_false }
    end

    describe "WHEN the filter has another user as it's value" do
      before do
        public_query.filter(filter_symbol, :values => [user2.id.to_s], :operator => "=")
        public_query.save!

        user.destroy
      end

      it { CostQuery.find_by_id(public_query.id).deserialize.filters.any?{ |f| f.is_a?(filter) }.should be_true }
      it { CostQuery.find_by_id(public_query.id).deserialize.filters.detect{ |f| f.is_a?(filter) }.values.should == [user2.id.to_s] }
    end

    describe "WHEN the filter has the deleted user and another user as it's value" do
      before do
        public_query.filter(filter_symbol, :values => [user.id.to_s, user2.id.to_s], :operator => "=")
        public_query.save!

        user.destroy
      end

      it { CostQuery.find_by_id(public_query.id).deserialize.filters.any?{ |f| f.is_a?(filter) }.should be_true }
      it { CostQuery.find_by_id(public_query.id).deserialize.filters.detect{ |f| f.is_a?(filter) }.values.should == [user2.id.to_s] }
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

