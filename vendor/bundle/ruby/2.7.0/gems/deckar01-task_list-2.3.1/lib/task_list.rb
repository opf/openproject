require 'task_list/summary'
require 'task_list/version'

# encoding: utf-8
class TaskList
  attr_reader :record

  # `record` is the resource with the Markdown source text with task list items
  # following this syntax:
  #
  #   - [ ] a task list item
  #   - [ ] another item
  #   - [x] a completed item
  #
  def initialize(record)
    @record = record
  end

  # Public: return the TaskList::Summary for this task list.
  #
  # Returns a TaskList::Summary.
  def summary
    @summary ||= TaskList::Summary.new(record.task_list_items)
  end

  class Item < Struct.new(:checkbox_text, :source)
    Complete = /\[[xX]\]/.freeze # see TaskList::Filter

    # Public: Check if a task list is complete.
    #
    # Examples
    #
    #   Item.new("- [x]").complete?
    #   # => true
    #
    #   Item.new("- [ ]").complete?
    #   # => false
    #
    # Returns true for checked list, false otherwise
    def complete?
      !!(checkbox_text =~ Complete)
    end
  end
end
