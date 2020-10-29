# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)
require 'task_list/summary'

class TaskList::SummaryTest < Minitest::Test
  def setup
    @complete   = make_item "[x]", "complete"
    @incomplete = make_item "[ ]", "incomplete"
    @items = [@complete, @incomplete]
    @summary = make_summary @items
  end

  def test_no_items
    summary = make_summary []
    assert !summary.items?, "no task list items are expected"
  end

  def test_items
    assert @summary.items?, "task list items are expected"
    assert_equal 2, @summary.item_count
  end

  def test_complete_count
    assert_equal 1, @summary.complete_count
  end

  def test_incomplete_count
    assert_equal 1, @summary.incomplete_count
  end

  protected

  def make_item(checkbox_text = "[ ]", source = "an item!")
    TaskList::Item.new(checkbox_text, source)
  end

  def make_summary(items)
    TaskList::Summary.new(items)
  end
end
