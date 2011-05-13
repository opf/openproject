require File.join(File.dirname(__FILE__), 'test_helper')

class ConditionsTest < Test::Unit::TestCase
  context 'Converted :if conditions' do
    setup do
      User.class_eval do
        def true; true; end
      end
    end

    should 'be an array' do
      assert_kind_of Array, User.vestal_journals_options[:if]
      User.prepare_journaled_options(:if => :true)
      assert_kind_of Array, User.vestal_journals_options[:if]
    end

    should 'have proc values' do
      User.prepare_journaled_options(:if => :true)
      assert User.vestal_journals_options[:if].all?{|i| i.is_a?(Proc) }
    end

    teardown do
      User.prepare_journaled_options(:if => [])
    end
  end

  context 'Converted :unless conditions' do
    setup do
      User.class_eval do
        def true; true; end
      end
    end

    should 'be an array' do
      assert_kind_of Array, User.vestal_journals_options[:unless]
      User.prepare_journaled_options(:unless => :true)
      assert_kind_of Array, User.vestal_journals_options[:unless]
    end

    should 'have proc values' do
      User.prepare_journaled_options(:unless => :true)
      assert User.vestal_journals_options[:unless].all?{|i| i.is_a?(Proc) }
    end

    teardown do
      User.prepare_journaled_options(:unless => [])
    end
  end

  context 'A new journal' do
    setup do
      User.class_eval do
        def true; true; end
        def false; false; end
      end

      @user = User.create(:name => 'Steve Richert')
      @count = @user.journals.count
    end

    context 'with :if conditions' do
      context 'that pass' do
        setup do
          User.prepare_journaled_options(:if => [:true])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'be created' do
          assert_equal @count + 1, @user.journals.count
        end
      end

      context 'that fail' do
        setup do
          User.prepare_journaled_options(:if => [:false])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end
    end

    context 'with :unless conditions' do
      context 'that pass' do
        setup do
          User.prepare_journaled_options(:unless => [:true])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end

      context 'that fail' do
        setup do
          User.prepare_journaled_options(:unless => [:false])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count + 1, @user.journals.count
        end
      end
    end

    context 'with :if and :unless conditions' do
      context 'that pass' do
        setup do
          User.prepare_journaled_options(:if => [:true], :unless => [:true])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end

      context 'that fail' do
        setup do
          User.prepare_journaled_options(:if => [:false], :unless => [:false])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end
    end

    teardown do
      User.prepare_journaled_options(:if => [], :unless => [])
    end
  end
end
