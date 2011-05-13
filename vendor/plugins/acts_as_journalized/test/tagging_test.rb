require File.join(File.dirname(__FILE__), 'test_helper')

class TaggingTest < Test::Unit::TestCase
  context 'Tagging a journal' do
    setup do
      @user = User.create(:name => 'Steve Richert')
      @user.update_attribute(:last_name, 'Jobs')
    end

    should "update the journal record's tag column" do
      tag_name = 'TAG'
      last_journal = @user.journals.last
      assert_not_equal tag_name, last_journal.tag
      @user.tag_journal(tag_name)
      assert_equal tag_name, last_journal.reload.tag
    end

    should 'create a journal record for an initial journal' do
      @user.revert_to(1)
      assert_nil @user.journals.at(1)
      @user.tag_journal('TAG')
      assert_not_nil @user.journals.at(1)
    end
  end

  context 'A tagged journal' do
    setup do
      user = User.create(:name => 'Steve Richert')
      user.update_attribute(:last_name, 'Jobs')
      user.tag_journal('TAG')
      @journal = user.journals.last
    end

    should 'return true for the "tagged?" method' do
      assert @journal.respond_to?(:tagged?)
      assert_equal true, @journal.tagged?
    end
  end
end
