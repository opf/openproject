# frozen_string_literal: true

module Shared
  module ListSub
    def setup
      (1..4).each do |i|
        node = ((i % 2 == 1) ? ListMixinSub1 : ListMixinSub2).new parent_id: 5000
        node.pos = i
        node.save!
      end
    end

    def test_reordering
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 2).first.move_lower
      assert_equal [1, 3, 2, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 2).first.move_higher
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 1).first.move_to_bottom
      assert_equal [2, 3, 4, 1], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 1).first.move_to_top
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 2).first.move_to_bottom
      assert_equal [1, 3, 4, 2], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 4).first.move_to_top
      assert_equal [4, 1, 3, 2], ListMixin.where(parent_id: 5000).order('pos').map(&:id)
    end

    def test_move_to_bottom_with_next_to_last_item
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)
      ListMixin.where(id: 3).first.move_to_bottom
      assert_equal [1, 2, 4, 3], ListMixin.where(parent_id: 5000).order('pos').map(&:id)
    end

    def test_next_prev
      assert_equal ListMixin.where(id: 2).first, ListMixin.where(id: 1).first.lower_item
      assert_nil ListMixin.where(id: 1).first.higher_item
      assert_equal ListMixin.where(id: 3).first, ListMixin.where(id: 4).first.higher_item
      assert_nil ListMixin.where(id: 4).first.lower_item
    end

    def test_next_prev_not_regular_sequence
      ListMixin.all.each do |item|
        item.update pos: item.pos * 5
      end

      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)
      assert_equal [5, 10, 15, 20], ListMixin.where(parent_id: 5000).order('id').map(&:pos)

      ListMixin.where(id: 2).first.move_lower
      assert_equal [1, 3, 2, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)
      assert_equal [5, 15, 10, 20], ListMixin.where(parent_id: 5000).order('id').map(&:pos)


      ListMixin.where(id: 2).first.move_higher
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)
      assert_equal [5, 10, 15, 20], ListMixin.where(parent_id: 5000).order('id').map(&:pos)

      ListMixin.where(id: 1).first.move_to_bottom
      assert_equal [2, 3, 4, 1], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 1).first.move_to_top
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 2).first.move_to_bottom
      assert_equal [1, 3, 4, 2], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 4).first.move_to_top
      assert_equal [4, 1, 3, 2], ListMixin.where(parent_id: 5000).order('pos').map(&:id)
    end

    def test_next_prev_groups
      li1 = ListMixin.where(id: 1).first
      li2 = ListMixin.where(id: 2).first
      li3 = ListMixin.where(id: 3).first
      li4 = ListMixin.where(id: 4).first
      assert_equal [li2, li3, li4], li1.lower_items
      assert_equal [li4], li3.lower_items
      assert_equal [li2, li3], li1.lower_items(2)
      assert_equal [], li4.lower_items

      assert_equal [li2, li1], li3.higher_items
      assert_equal [li1], li2.higher_items
      assert_equal [li3, li2], li4.higher_items(2)
      assert_equal [], li1.higher_items
    end

    def test_next_prev_groups_with_same_position
      li1 = ListMixin.where(id: 1).first
      li2 = ListMixin.where(id: 2).first
      li3 = ListMixin.where(id: 3).first
      li4 = ListMixin.where(id: 4).first

      li3.update_column(:pos, 2) # Make the same position as li2

      assert_equal [1, 2, 2, 4], ListMixin.order(:pos).pluck(:pos)

      assert_equal [li3, li4], li2.lower_items
      assert_equal [li2, li4], li3.lower_items

      assert_equal [li3, li1], li2.higher_items
      assert_equal [li2, li1], li3.higher_items
    end

    def test_injection
      item = ListMixin.new("parent_id"=>1)
      assert_equal({ parent_id: 1 }, item.scope_condition)
      assert_equal "pos", item.position_column
    end

    def test_insert_at
      new = ListMixin.create("parent_id" => 20)
      assert_equal 1, new.pos

      new = ListMixinSub1.create("parent_id" => 20)
      assert_equal 2, new.pos

      new = ListMixinSub1.create("parent_id" => 20)
      assert_equal 3, new.pos

      new_noup = ListMixinSub1.acts_as_list_no_update { ListMixinSub1.create("parent_id" => 20) }
      assert_equal_or_nil $default_position, new_noup.pos

      new4 = ListMixin.create("parent_id" => 20)
      assert_equal 4, new4.pos

      new4.insert_at(3)
      assert_equal 3, new4.pos

      new.reload
      assert_equal 4, new.pos

      new.insert_at(2)
      assert_equal 2, new.pos

      new4.reload
      assert_equal 4, new4.pos

      new5 = ListMixinSub1.create("parent_id" => 20)
      assert_equal 5, new5.pos

      new5.insert_at(1)
      assert_equal 1, new5.pos

      new4.reload
      assert_equal 5, new4.pos

      new_noup.reload
      assert_equal_or_nil $default_position, new_noup.pos
    end

    def test_delete_middle
      assert_equal [1, 2, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      ListMixin.where(id: 2).first.destroy

      assert_equal [1, 3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      assert_equal 1, ListMixin.where(id: 1).first.pos
      assert_equal 2, ListMixin.where(id: 3).first.pos
      assert_equal 3, ListMixin.where(id: 4).first.pos

      ListMixin.where(id: 1).first.destroy

      assert_equal [3, 4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      assert_equal 1, ListMixin.where(id: 3).first.pos
      assert_equal 2, ListMixin.where(id: 4).first.pos

      ListMixin.acts_as_list_no_update { ListMixin.where(id: 3).first.destroy }

      assert_equal [4], ListMixin.where(parent_id: 5000).order('pos').map(&:id)

      assert_equal 2, ListMixin.where(id: 4).first.pos
    end

    def test_acts_as_list_class
      assert_equal TheBaseClass, TheBaseSubclass.new.acts_as_list_class
      assert_equal TheAbstractSubclass, TheAbstractSubclass.new.acts_as_list_class
    end
  end
end
