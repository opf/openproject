class Widget::Base
  attr_reader :engine

  def self.render(subject)
    new(subject).render
  end

  def initialize(query)
    @query = query
    @engine = query.engine
  end

  def render
    raise NotImplementedError,  "#render is not implemented in the subclasses"
  end
end
