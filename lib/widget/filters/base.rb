class Widget::Filters::Base < Widget::Base
  attr_reader :filter

  def initialize(filter)
    @filter = filter
    @engine = engine
  end
end
