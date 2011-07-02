require 'test_helper'

class UsersTest < Test::Unit::TestCase
  context 'The user responsible for an update' do
    setup do
      @updated_by = User.create(:name => 'Steve Jobs')
      @user = User.create(:name => 'Steve Richert')
    end

    should 'default to nil' do
      @user.update_attributes(:first_name => 'Stephen')
      assert_nil @user.journals.last.user
    end

    should 'accept and return an ActiveRecord user' do
      @user.update_attributes(:first_name => 'Stephen', :updated_by => @updated_by)
      assert_equal @updated_by, @user.journals.last.user
    end

    should 'accept and return a string user name' do
      @user.update_attributes(:first_name => 'Stephen', :updated_by => @updated_by.name)
      assert_equal @updated_by.name, @user.journals.last.user
    end
  end
end
