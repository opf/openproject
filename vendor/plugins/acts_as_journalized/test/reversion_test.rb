require File.join(File.dirname(__FILE__), 'test_helper')

class RejournalTest < Test::Unit::TestCase
  context 'A model rejournal' do
    setup do
      @user, @attributes, @times = User.new, {}, {}
      names = ['Steve Richert', 'Stephen Richert', 'Stephen Jobs', 'Steve Jobs']
      time = names.size.hours.ago
      names.each do |name|
        @user.update_attribute(:name, name)
        @attributes[@user.journal] = @user.attributes
        time += 1.hour
        if last_journal = @user.journals.last
          last_journal.update_attribute(:created_at, time)
        end
        @times[@user.journal] = time
      end
      @user.reload.journals.reload
      @first_journal, @last_journal = @attributes.keys.min, @attributes.keys.max
    end

    should 'return the new journal number' do
      new_journal = @user.revert_to(@first_journal)
      assert_equal @first_journal, new_journal
    end

    should 'change the journal number when saved' do
      current_journal = @user.journal
      @user.revert_to!(@first_journal)
      assert_not_equal current_journal, @user.journal
    end

    should 'do nothing for a invalid argument' do
      current_journal = @user.journal
      [nil, :bogus, 'bogus', (1..2)].each do |invalid|
        @user.revert_to(invalid)
        assert_equal current_journal, @user.journal
      end
    end

    should 'be able to target a journal number' do
      @user.revert_to(1)
      assert 1, @user.journal
    end

    should 'be able to target a date and time' do
      @times.each do |journal, time|
        @user.revert_to(time + 1.second)
        assert_equal journal, @user.journal
      end
    end

    should 'be able to target a journal object' do
      @user.journals.each do |journal|
        @user.revert_to(journal)
        assert_equal journal.number, @user.journal
      end
    end

    should "correctly roll back the model's attributes" do
      timestamps = %w(created_at created_on updated_at updated_on)
      @attributes.each do |journal, attributes|
        @user.revert_to!(journal)
        assert_equal attributes.except(*timestamps), @user.attributes.except(*timestamps)
      end
    end
  end
end
