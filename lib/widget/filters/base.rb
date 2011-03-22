class Widget::Filters::Base < Widget::Base
  attr_reader :filter, :filter_class

  def initialize(filter)
    if filter.class == Class
      @filter_class = filter
      @filter = filter.new
    else
      @filter = filter
      @filter_class = filter.class
    end
    @engine = filter.engine
  end
  
  ##
  # Indicates whether this Filter is a multiple choice filter,
  # meaning that the user must select a value of a given set of choices.
  def is_multiple_choice?
    false
  end
end
