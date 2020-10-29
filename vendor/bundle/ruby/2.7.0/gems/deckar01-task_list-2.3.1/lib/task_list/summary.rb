# encoding: utf-8
require 'html/pipeline'
require 'task_list'

class TaskList
  # Provides a summary of provided TaskList `items`.
  #
  # `items` is an Array of TaskList::Item objects.
  class Summary < Struct.new(:items)
    # Public: returns true if there are any TaskList::Item objects.
    def items?
      item_count > 0
    end

    # Public: returns the number of TaskList::Item objects.
    def item_count
      items.size
    end

    # Public: returns the number of complete TaskList::Item objects.
    def complete_count
      items.select{ |i| i.complete? }.size
    end

    # Public: returns the number of incomplete TaskList::Item objects.
    def incomplete_count
      items.select{ |i| !i.complete? }.size
    end
  end
end
