#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class ResetTest < Test::Unit::TestCase
  context 'Resetting a model' do
    setup do
      @original_dependent = User.reflect_on_association(:journals).options[:dependent]
      @user, @journals = User.new, []
      @names = ['Steve Richert', 'Stephen Richert', 'Stephen Jobs', 'Steve Jobs']
      @names.each do |name|
        @user.update_attribute(:name, name)
        @journals << @user.journal
      end
    end

    should "properly revert the model's attributes" do
      @journals.reverse.each_with_index do |journal, i|
        @user.reset_to!(journal)
        assert_equal @names.reverse[i], @user.name
      end
    end

    should 'dissociate all journals after the target' do
      @journals.reverse.each do |journal|
        @user.reset_to!(journal)
        assert_equal 0, @user.journals(true).after(journal).count
      end
    end

    context 'with the :dependent option as :delete_all' do
      setup do
        User.reflect_on_association(:journals).options[:dependent] = :delete_all
      end

      should 'delete all journals after the target journal' do
        @journals.reverse.each do |journal|
          later_journals = @user.journals.after(journal)
          @user.reset_to!(journal)
          later_journals.each do |later_journal|
            assert_raise ActiveRecord::RecordNotFound do
              later_journal.reload
            end
          end
        end
      end

      should 'not destroy all journals after the target journal' do
        VestalVersions::Version.any_instance.stubs(:destroy).raises(RuntimeError)
        @journals.reverse.each do |journal|
          assert_nothing_raised do
            @user.reset_to!(journal)
          end
        end
      end
    end

    context 'with the :dependent option as :destroy' do
      setup do
        User.reflect_on_association(:journals).options[:dependent] = :destroy
      end

      should 'delete all journals after the target journal' do
        @journals.reverse.each do |journal|
          later_journals = @user.journals.after(journal)
          @user.reset_to!(journal)
          later_journals.each do |later_journal|
            assert_raise ActiveRecord::RecordNotFound do
              later_journal.reload
            end
          end
        end
      end

      should 'destroy all journals after the target journal' do
        VestalVersions::Version.any_instance.stubs(:destroy).raises(RuntimeError)
        @journals.reverse.each do |journal|
          later_journals = @user.journals.after(journal)
          if later_journals.empty?
            assert_nothing_raised do
              @user.reset_to!(journal)
            end
          else
            assert_raise RuntimeError do
              @user.reset_to!(journal)
            end
          end
        end
      end
    end

    context 'with the :dependent option as :nullify' do
      setup do
        User.reflect_on_association(:journals).options[:dependent] = :nullify
      end

      should 'leave all journals after the target journal' do
        @journals.reverse.each do |journal|
          later_journals = @user.journals.after(journal)
          @user.reset_to!(journal)
          later_journals.each do |later_journal|
            assert_nothing_raised do
              later_journal.reload
            end
          end
        end
      end
    end

    teardown do
      User.reflect_on_association(:journals).options[:dependent] = @original_dependent
    end
  end
end
