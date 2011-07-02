require File.join(File.dirname(__FILE__), 'test_helper')

class ReloadTest < Test::Unit::TestCase
  context 'Reloading a reverted model' do
    setup do
      @user = User.create(:name => 'Steve Richert')
      first_version = @user.version
      @user.update_attribute(:last_name, 'Jobs')
      @last_version = @user.version
      @user.revert_to(first_version)
    end

    should 'reset the journal number to the most recent journal' do
      assert_not_equal @last_journal, @user.journal
      @user.reload
      assert_equal @last_journal, @user.journal
    end
  end
end
