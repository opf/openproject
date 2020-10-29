# frozen_string_literal: true

module Shared
  module List
    def setup
      (1..4).each do |counter|
        node = ListMixin.new parent_id: 5
        node.pos = counter
        node.save!
      end
    end

    def test_current_position
      first_item = ListMixin.where(parent_id: 5).first
      assert_equal 1, first_item.current_position
      first_item.remove_from_list
      assert_nil first_item.current_position
    end

    def test_reordering
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 2).first.move_lower
      assert_equal [1, 3, 2, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 2).first.move_higher
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 1).first.move_to_bottom
      assert_equal [2, 3, 4, 1], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 1).first.move_to_top
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 2).first.move_to_bottom
      assert_equal [1, 3, 4, 2], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 4).first.move_to_top
      assert_equal [4, 1, 3, 2], ListMixin.where(parent_id: 5).order('pos').map(&:id)
    end

    def test_move_to_bottom_with_next_to_last_item
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)
      ListMixin.where(id: 3).first.move_to_bottom
      assert_equal [1, 2, 4, 3], ListMixin.where(parent_id: 5).order('pos').map(&:id)
    end

    def test_next_prev
      assert_equal ListMixin.where(id: 2).first, ListMixin.where(id: 1).first.lower_item
      assert_nil ListMixin.where(id: 1).first.higher_item
      assert_equal ListMixin.where(id: 3).first, ListMixin.where(id: 4).first.higher_item
      assert_nil ListMixin.where(id: 4).first.lower_item
    end

    def test_injection
      item = ListMixin.new(parent_id: 1)
      assert_equal({ parent_id: 1 }, item.scope_condition)
      assert_equal "pos", item.position_column
    end

    def test_insert
      new = ListMixin.create(parent_id: 20)
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?

      new = ListMixin.create(parent_id: 20)
      assert_equal 2, new.pos
      assert !new.first?
      assert new.last?

      new = ListMixin.acts_as_list_no_update { ListMixin.create(parent_id: 20) }
      assert_equal_or_nil $default_position, new.pos
      assert_equal $default_position.is_a?(Integer), new.first?
      assert !new.last?

      new = ListMixin.create(parent_id: 20)
      assert_equal 3, new.pos
      assert !new.first?
      assert new.last?

      new = ListMixin.create(parent_id: 0)
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?
    end

    def test_insert_at
      new = ListMixin.create(parent_id: 20)
      assert_equal 1, new.pos

      new = ListMixin.create(parent_id: 20)
      assert_equal 2, new.pos

      new = ListMixin.create(parent_id: 20)
      assert_equal 3, new.pos

      new_noup = ListMixin.acts_as_list_no_update { ListMixin.create(parent_id: 20) }
      assert_equal_or_nil $default_position, new_noup.pos

      new4 = ListMixin.create(parent_id: 20)
      assert_equal 4, new4.pos

      new4.insert_at(3)
      assert_equal 3, new4.pos

      new.reload
      assert_equal 4, new.pos

      new.insert_at(2)
      assert_equal 2, new.pos

      new4.reload
      assert_equal 4, new4.pos

      new5 = ListMixin.create(parent_id: 20)
      assert_equal 5, new5.pos

      new5.insert_at(1)
      assert_equal 1, new5.pos

      new4.reload
      assert_equal 5, new4.pos

      new_noup.reload
      assert_equal_or_nil $default_position, new_noup.pos

      last1 = ListMixin.where('pos IS NOT NULL').order('pos').last
      last2 = ListMixin.where('pos IS NOT NULL').order('pos').last
      last1.insert_at(1)
      last2.insert_at(1)
      pos_list = ListMixin.where(parent_id: 20).order("pos ASC#{' NULLS FIRST' if ENV['DB'] == 'postgresql'}").map(&:pos)
      assert_equal [$default_position, 1, 2, 3, 4, 5], pos_list
    end

    def test_insert_at_after_dup
      new1 = ListMixin.create(parent_id: 20)
      new2 = ListMixin.create(parent_id: 20)
      new3 = ListMixin.create(parent_id: 20)

      duped = new1.dup
      duped.save
      [new1, new2, new3, duped].map(&:reload)

      assert_equal [1, 2, 3, 4], [duped.pos, new1.pos, new2.pos, new3.pos]
    end

    def test_delete_middle
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 2).first.destroy

      assert_equal [1, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 1, ListMixin.where(id: 1).first.pos
      assert_equal 2, ListMixin.where(id: 3).first.pos
      assert_equal 3, ListMixin.where(id: 4).first.pos

      ListMixin.where(id: 1).first.destroy

      assert_equal [3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 1, ListMixin.where(id: 3).first.pos
      assert_equal 2, ListMixin.where(id: 4).first.pos

      ListMixin.acts_as_list_no_update { ListMixin.where(id: 3).first.destroy }

      assert_equal [4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 2, ListMixin.where(id: 4).first.pos
    end

    def test_with_string_based_scope
      new = ListWithStringScopeMixin.create(parent_id: 500)
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?
    end

    def test_nil_scope
      new1, new2, new3 = ListMixin.create, ListMixin.create, ListMixin.create
      new2.move_higher
      assert_equal [new2, new1, new3].map(&:id), ListMixin.where(parent_id: nil).order('pos').map(&:id)
    end

    def test_update_position_when_scope_changes
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)
      ListMixin.create(parent_id: 6)

      ListMixin.where(id: 2).first.move_within_scope(6)

      assert_equal 2, ListMixin.where(id: 2).first.pos

      assert_equal [1, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 1, ListMixin.where(id: 1).first.pos
      assert_equal 2, ListMixin.where(id: 3).first.pos
      assert_equal 3, ListMixin.where(id: 4).first.pos

      ListMixin.where(id: 2).first.move_within_scope(5)
      assert_equal [1, 3, 4, 2], ListMixin.where(parent_id: 5).order('pos').map(&:id)
    end

    def test_remove_from_list_should_then_fail_in_list?
      assert_equal true, ListMixin.where(id: 1).first.in_list?
      ListMixin.where(id: 1).first.remove_from_list
      assert_equal false, ListMixin.where(id: 1).first.in_list?
    end

    def test_remove_from_list_should_set_position_to_nil
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 2).first.remove_from_list

      assert_equal 1,   ListMixin.where(id: 1).first.pos
      assert_nil        ListMixin.where(id: 2).first.pos
      assert_equal 2,   ListMixin.where(id: 3).first.pos
      assert_equal 3,   ListMixin.where(id: 4).first.pos
    end

    def test_remove_before_destroy_does_not_shift_lower_items_twice
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      ListMixin.where(id: 2).first.remove_from_list
      ListMixin.where(id: 2).first.destroy

      assert_equal [1, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 1, ListMixin.where(id: 1).first.pos
      assert_equal 2, ListMixin.where(id: 3).first.pos
      assert_equal 3, ListMixin.where(id: 4).first.pos
    end

    def test_before_destroy_callbacks_do_not_update_position_to_nil_before_deleting_the_record
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      # We need to trigger all the before_destroy callbacks without actually
      # destroying the record so we can see the affect the callbacks have on
      # the record.
      list = ListMixin.where(id: 2).first
      if list.respond_to?(:run_callbacks)
        list.run_callbacks(:destroy)
      else
        list.send(:callback, :before_destroy)
      end

      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      assert_equal 1, ListMixin.where(id: 1).first.pos
      assert_equal 2, ListMixin.where(id: 2).first.pos
      assert_equal 2, ListMixin.where(id: 3).first.pos
      assert_equal 3, ListMixin.where(id: 4).first.pos
    end

    def test_before_create_callback_adds_to_bottom
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      new = ListMixin.create(parent_id: 5)
      assert_equal 5, new.pos
      assert !new.first?
      assert new.last?

      assert_equal [1, 2, 3, 4, 5], ListMixin.where(parent_id: 5).order('pos').map(&:id)
    end

    def test_before_create_callback_adds_to_given_position
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      new = ListMixin.new(parent_id: 5)
      new.pos = 1
      new.save!
      assert_equal 1, new.pos
      assert new.first?
      assert !new.last?

      assert_equal [5, 1, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      new6 = ListMixin.new(parent_id: 5)
      new6.pos = 3
      new6.save!
      assert_equal 3, new6.pos
      assert !new6.first?
      assert !new6.last?

      assert_equal [5, 1, 6, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos').map(&:id)

      new = ListMixin.new(parent_id: 5)
      new.pos = 3
      ListMixin.acts_as_list_no_update { new.save! }
      assert_equal 3, new.pos
      assert_equal 3, new6.pos
      assert !new.first?
      assert !new.last?

      assert_equal [5, 1, 6, 7, 2, 3, 4], ListMixin.where(parent_id: 5).order('pos, id').map(&:id)
    end

    def test_non_persisted_records_dont_get_lock_called
      new = ListMixin.new(parent_id: 5)
      new.destroy
    end

    def test_invalid_records_dont_get_inserted
      new = ListMixinError.new(parent_id: 5, state: nil)
      assert !new.valid?
      new.insert_at(1)
      assert !new.persisted?
    end

    def test_invalid_records_raise_error_with_insert_at!
      new = ListMixinError.new(parent_id: 5, state: nil)
      assert !new.valid?
      assert_raises ActiveRecord::RecordInvalid do
        new.insert_at!(1)
      end
    end
  end
end
