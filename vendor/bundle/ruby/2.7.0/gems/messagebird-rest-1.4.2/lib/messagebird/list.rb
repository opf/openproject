require 'messagebird/base'

class List < MessageBird::Base
  attr_accessor :offset, :limit, :count, :totalCount, :links, :items

  # type will be used to create objects for the items, e.g.
  # List.new(Contact, {}).
  def initialize(type, json)
    @type = type

    super(json)
  end

  def items=(value)
    @items = value.map { |i| @type.new i }
  end

  def [](index)
    @items[index]
  end

end
