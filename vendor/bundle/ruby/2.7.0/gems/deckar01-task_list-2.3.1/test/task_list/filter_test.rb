# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)
require 'task_list/filter'

class TaskList::FilterTest < Minitest::Test
  def setup
    @pipeline = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      TaskList::Filter
    ], {}, {}

    @context = {}
    @item_selector = "input.task-list-item-checkbox[type=checkbox]"
  end

  def test_has_no_effect_on_lists_with_no_tasks
    text = <<-md
- plain
- bullets
    md
    assert_equal 0, filter(text)[:output].css('ul.task-list').size
  end

  def test_filters_items_in_a_list
    text = <<-md
- [ ] incomplete
- [x] complete
    md
    assert_equal 2, filter(text)[:output].css(@item_selector).size
  end

  def test_filters_items_with_HTML_contents
    text = <<-md
- [ ] incomplete **with bold** text
- [x] complete __with italic__ text
    md
    assert_equal 2, filter(text)[:output].css(@item_selector).size
  end

  def test_filters_items_in_a_list_wrapped_in_paras
    # See issue #7951 for details.
    text = <<-md
- [ ] one
- [ ] this one will be wrapped in a para

- [ ] this one too, wtf
    md
    assert_equal 3, filter(text)[:output].css(@item_selector).size
  end

  def test_populates_result_with_task_list_items
    text = <<-md
- [ ] incomplete
- [x] complete
    md

    result = filter(text)
    assert !result[:task_list_items].empty?
    incomplete, complete = result[:task_list_items]

    assert incomplete
    assert !incomplete.complete?

    assert complete
    assert complete.complete?
  end

  def test_skips_lists_in_code_blocks
    code = <<-md
```
- [ ] incomplete
- [x] complete
```
    md

    assert filter(code)[:output].css(@item_selector).empty?,
      "should not have any task list items"
  end

  def test_handles_encoding_correctly
    unicode = "中文"
    text = <<-md
- [ ] #{unicode}
    md
    assert item = filter(text)[:output].css('.task-list-item').pop
    assert_equal unicode, item.text.strip
  end

  def test_handles_nested_items
    text = <<-md
- [ ] one
  - [ ] one.one
    md
    assert item = filter(text)[:output].css('.task-list-item .task-list-item').pop
  end

  def test_handles_complicated_nested_items
    text = <<-md
- [ ] one
  - [ ] one.one
  - [x] one.two
    - [ ] one.two.one
    - [ ] one.two.two
  - [ ] one.three
  - [ ] one.four
- [ ] two
  - [x] two.one
  - [ ] two.two
- [ ] three
    md

    assert_equal 6 + 2, filter(text)[:output].css('.task-list-item .task-list-item').size
    assert_equal 2, filter(text)[:output].css('.task-list-item .task-list-item .task-list-item').size
  end

  # NOTE: This is an edge case experienced regularly by users using a Swiss
  # German keyboard.
  # See: https://github.com/github/github/pull/18362
  def test_non_breaking_space_between_brackets
    text = "- [\xC2\xA0] ok"
    assert item = filter(text)[:output].css('.task-list-item').pop, "item expected"
    assert_equal 'ok', item.text.strip
  end

  # See: https://github.com/github/github/pull/18362
  def test_non_breaking_space_between_brackets_in_paras
    text = <<-md
- [\xC2\xA0] one
- [\xC2\xA0] this one will be wrapped in a para

- [\xC2\xA0] this one too, wtf
    md
    assert_equal 3, filter(text)[:output].css(@item_selector).size
  end

  def test_capital_X
    text = <<-md
- [x] lower case
- [X] capital
    md
    assert_equal 2, filter(text)[:output].css("[checked]").size
  end

  protected

  def filter(input, context = @context, result = nil)
    result ||= {}
    @pipeline.call(input, context, result)
  end
end
