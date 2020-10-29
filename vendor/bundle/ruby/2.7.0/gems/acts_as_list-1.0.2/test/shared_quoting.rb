# frozen_string_literal: true

module Shared
  module Quoting

    def setup
      3.times { |counter| QuotedList.create! order: counter }
    end

    def test_create
      assert_equal QuotedList.in_list.size, 3
    end

    # This test execute raw queries involving table name
    def test_moving
      item = QuotedList.first
      item.higher_items
      item.lower_items
      item.send :bottom_item # Part of private api
    end

  end
end
