#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class ChangesTest < Test::Unit::TestCase
  context "A journal's changes" do
    setup do
      @user = User.create(:name => 'Steve Richert')
      @user.update_attribute(:last_name, 'Jobs')
      @changes = @user.journals.last.changes
    end

    should 'be a hash' do
      assert_kind_of Hash, @changes
    end

    should 'not be empty' do
      assert !@changes.empty?
    end

    should 'have string keys' do
      @changes.keys.each do |key|
        assert_kind_of String, key
      end
    end

    should 'have array values' do
      @changes.values.each do |value|
        assert_kind_of Array, value
      end
    end

    should 'have two-element values' do
      @changes.values.each do |value|
        assert_equal 2, value.size
      end
    end

    should 'have unique-element values' do
      @changes.values.each do |value|
        assert_equal value.uniq, value
      end
    end

    should "equal the model's changes" do
      @user.first_name = 'Stephen'
      model_changes = @user.changes
      @user.save
      changes = @user.journals.last.changes
      assert_equal model_changes, changes
    end
  end

  context 'A hash of changes' do
    setup do
      @changes = {'first_name' => ['Steve', 'Stephen']}
      @other = {'first_name' => ['Catie', 'Catherine']}
    end

    should 'properly append other changes' do
      expected = {'first_name' => ['Steve', 'Catherine']}
      changes = @changes.append_changes(@other)
      assert_equal expected, changes
      @changes.append_changes!(@other)
      assert_equal expected, @changes
    end

    should 'properly prepend other changes' do
      expected = {'first_name' => ['Catie', 'Stephen']}
      changes = @changes.prepend_changes(@other)
      assert_equal expected, changes
      @changes.prepend_changes!(@other)
      assert_equal expected, @changes
    end

    should 'be reversible' do
      expected = {'first_name' => ['Stephen', 'Steve']}
      changes = @changes.reverse_changes
      assert_equal expected, changes
      @changes.reverse_changes!
      assert_equal expected, @changes
    end
  end

  context 'The changes between two journals' do
    setup do
      name = 'Steve Richert'
      @user = User.create(:name => name)              # 1
      @user.update_attribute(:last_name, 'Jobs')      # 2
      @user.update_attribute(:first_name, 'Stephen')  # 3
      @user.update_attribute(:last_name, 'Richert')   # 4
      @user.update_attribute(:name, name)             # 5
      @version = @user.version
    end

    should 'be a hash' do
      1.upto(@version) do |i|
        1.upto(@version) do |j|
          changes = @user.changes_between(i, j)
          assert_kind_of Hash, changes
        end
      end
    end

    should 'have string keys' do
      1.upto(@version) do |i|
        1.upto(@version) do |j|
          changes = @user.changes_between(i, j)
          changes.keys.each do |key|
            assert_kind_of String, key
          end
        end
      end
    end

    should 'have array values' do
      1.upto(@version) do |i|
        1.upto(@version) do |j|
          changes = @user.changes_between(i, j)
          changes.values.each do |value|
            assert_kind_of Array, value
          end
        end
      end
    end

    should 'have two-element values' do
      1.upto(@version) do |i|
        1.upto(@version) do |j|
          changes = @user.changes_between(i, j)
          changes.values.each do |value|
            assert_equal 2, value.size
          end
        end
      end
    end

    should 'have unique-element values' do
      1.upto(@version) do |i|
        1.upto(@version) do |j|
          changes = @user.changes_between(i, j)
          changes.values.each do |value|
            assert_equal value.uniq, value
          end
        end
      end
    end

    should 'be empty between identical versions' do
      assert @user.changes_between(1, @version).empty?
      assert @user.changes_between(@version, 1).empty?
    end

    should 'be should reverse with direction' do
      1.upto(@version) do |i|
        i.upto(@version) do |j|
          up    = @user.changes_between(i, j)
          down  = @user.changes_between(j, i)
          assert_equal up, down.reverse_changes
        end
      end
    end

    should 'be empty with invalid arguments' do
      1.upto(@version) do |i|
        assert @user.changes_between(i, nil)
        assert @user.changes_between(nil, i)
      end
    end
  end
end
