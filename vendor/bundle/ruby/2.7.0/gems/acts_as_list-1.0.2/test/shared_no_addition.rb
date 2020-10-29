# frozen_string_literal: true

module Shared
  module NoAddition
    def setup
      (1..4).each { |counter| NoAdditionMixin.create! pos: counter, parent_id: 5 }
    end

    def test_insert
      new = NoAdditionMixin.create(parent_id: 20)
      assert_nil new.pos
      assert !new.in_list?

      new = NoAdditionMixin.create(parent_id: 20)
      assert_nil new.pos
    end

    def test_update_does_not_add_to_list
      new = NoAdditionMixin.create(parent_id: 20)
      new.update_attribute(:updated_at, Time.now) # force some change
      new.reload

      assert !new.in_list?
    end

    def test_update_scope_does_not_add_to_list
      new = NoAdditionMixin.create

      new.update_attribute(:parent_id, 20)
      new.reload
      assert !new.in_list?

      new.update_attribute(:parent_id, 5)
      new.reload
      assert !new.in_list?
    end
  end
end
