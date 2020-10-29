# frozen_string_literal: true

module Shared
  module TopAddition
    def setup
      (1..4).each { |counter| TopAdditionMixin.create! pos: counter, parent_id: 5 }
    end

    def test_setup_state
      # If we explicitly define a position (as above) then that position is what gets applied
      assert_equal [1, 2, 3, 4], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)
    end

    def test_reordering
      TopAdditionMixin.where(id: 2).first.move_lower
      assert_equal [1, 3, 2, 4], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)

      TopAdditionMixin.where(id: 2).first.move_higher
      assert_equal [1, 2, 3, 4], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)

      TopAdditionMixin.where(id: 1).first.move_to_bottom
      assert_equal [2, 3, 4, 1], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)

      TopAdditionMixin.where(id: 1).first.move_to_top
      assert_equal [1, 2, 3, 4], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)

      TopAdditionMixin.where(id: 2).first.move_to_bottom
      assert_equal [1, 3, 4, 2], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)

      TopAdditionMixin.where(id: 4).first.move_to_top
      assert_equal [4, 1, 3, 2], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)
    end

    def test_injection
      item = TopAdditionMixin.new(parent_id: 1)
      assert_equal({ parent_id: 1 }, item.scope_condition)
      assert_equal "pos", item.position_column
    end

    def test_insert
      new = TopAdditionMixin.create(parent_id: 20)
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?

      new = TopAdditionMixin.create(parent_id: 20)
      assert_equal 1, new.pos
      assert new.first?
      assert !new.last?

      new = TopAdditionMixin.acts_as_list_no_update { TopAdditionMixin.create(parent_id: 20) }
      assert_equal_or_nil $default_position, new.pos
      assert_equal $default_position.is_a?(Integer), new.first?
      assert !new.last?

      new = TopAdditionMixin.create(parent_id: 20)
      assert_equal 1, new.pos
      assert_equal $default_position.nil?, new.first?
      assert !new.last?

      new = TopAdditionMixin.create(parent_id: 0)
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?
    end

    def test_insert_at
      new = TopAdditionMixin.create(parent_id: 20)
      assert_equal 1, new.pos

      new = TopAdditionMixin.create(parent_id: 20)
      assert_equal 1, new.pos

      new = TopAdditionMixin.create(parent_id: 20)
      assert_equal 1, new.pos

      new = TopAdditionMixin.acts_as_list_no_update { TopAdditionMixin.create(parent_id: 20) }
      assert_equal_or_nil $default_position, new.pos

      new4 = TopAdditionMixin.create(parent_id: 20)
      assert_equal 1, new4.pos

      new4.insert_at(3)
      assert_equal 3, new4.pos
    end

    def test_supplied_position
      new = TopAdditionMixin.create(parent_id: 20, pos: 3)
      assert_equal 3, new.pos
    end

    def test_delete_middle
      TopAdditionMixin.where(id: 2).first.destroy

      assert_equal [1, 3, 4], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 1, TopAdditionMixin.where(id: 1).first.pos
      assert_equal 2, TopAdditionMixin.where(id: 3).first.pos
      assert_equal 3, TopAdditionMixin.where(id: 4).first.pos

      TopAdditionMixin.acts_as_list_no_update { TopAdditionMixin.where(id: 3).first.destroy }

      assert_equal [1, 4], TopAdditionMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 1, TopAdditionMixin.where(id: 1).first.pos
      assert_equal 3, TopAdditionMixin.where(id: 4).first.pos
    end

  end
end
