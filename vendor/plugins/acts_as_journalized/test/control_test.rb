#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class ControlTest < Test::Unit::TestCase
  context 'Within a skip_journal block,' do
    setup do
      @user = User.create(:name => 'Steve Richert')
      @count = @user.journals.count
    end

    context 'a model update' do
      setup do
        @user.skip_journal do
          @user.update_attribute(:last_name, 'Jobs')
        end
      end

      should 'not create a journal' do
        assert_equal @count, @user.journals.count
      end
    end

    context 'multiple model updates' do
      setup do
        @user.skip_journal do
          @user.update_attribute(:first_name, 'Stephen')
          @user.update_attribute(:last_name, 'Jobs')
          @user.update_attribute(:first_name, 'Steve')
        end
      end

      should 'not create a journal' do
        assert_equal @count, @user.journals.count
      end
    end
  end

  context 'Within a merge_journal block,' do
    setup do
      @user = User.create(:name => 'Steve Richert')
      @count = @user.journals.count
    end

    context 'a model update' do
      setup do
        @user.merge_journal do
          @user.update_attribute(:last_name, 'Jobs')
        end
      end

      should 'create a journal' do
        assert_equal @count + 1, @user.journals.count
      end
    end

    context 'multiple model updates' do
      setup do
        @user.merge_journal do
          @user.update_attribute(:first_name, 'Stephen')
          @user.update_attribute(:last_name, 'Jobs')
          @user.update_attribute(:first_name, 'Steve')
        end
      end

      should 'create a journal' do
        assert_equal @count + 1, @user.journals.count
      end
    end
  end

  context 'Within a append_journal block' do
    context '(when no journals exist),' do
      setup do
        @user = User.create(:name => 'Steve Richert')
        @count = @user.journals.count
      end

      context 'a model update' do
        setup do
          @user.append_journal do
            @user.update_attribute(:last_name, 'Jobs')
          end
        end

        should 'create a journal' do
          assert_equal @count + 1, @user.journals.count
        end
      end

      context 'multiple model updates' do
        setup do
          @user.append_journal do
            @user.update_attribute(:first_name, 'Stephen')
            @user.update_attribute(:last_name, 'Jobs')
            @user.update_attribute(:first_name, 'Steve')
          end
        end

        should 'create a journal' do
          assert_equal @count + 1, @user.journals.count
        end
      end
    end

    context '(when journals exist),' do
      setup do
        @user = User.create(:name => 'Steve Richert')
        @user.update_attribute(:last_name, 'Jobs')
        @user.update_attribute(:last_name, 'Richert')
        @last_journal = @user.journals.last
        @count = @user.journals.count
      end

      context 'a model update' do
        setup do
          @user.append_journal do
            @user.update_attribute(:last_name, 'Jobs')
          end
        end

        should 'not create a journal' do
          assert_equal @count, @user.journals.count
        end

        should 'update the last journal' do
          last_journal = @user.journals(true).last
          assert_equal @last_journal.id, last_journal.id
          assert_not_equal @last_journal.attributes, last_journal.attributes
        end
      end

      context 'multiple model updates' do
        setup do
          @user.append_journal do
            @user.update_attribute(:first_name, 'Stephen')
            @user.update_attribute(:last_name, 'Jobs')
            @user.update_attribute(:first_name, 'Steve')
          end
        end

        should 'not create a journal' do
          assert_equal @count, @user.journals.count
        end

        should 'update the last journal' do
          last_journal = @user.journals(true).last
          assert_equal @last_journal.id, last_journal.id
          assert_not_equal @last_journal.attributes, last_journal.attributes
        end
      end
    end
  end
end
