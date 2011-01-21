class Widget::Filters::Base < Widget::Base
  attr_reader :filter, :filter_class

  def initialize(filter)
    if filter.class == Class
      @filter_class = filter
      @filter = filter.new
    else
      @filter = filter
      @filter.class = filter.class
    end
    @engine = filter.engine
  end
end
