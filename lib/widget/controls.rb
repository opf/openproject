class Widget::Controls < Widget::Base
  extend ProactiveAutoloader

  def cache_key
    "#{super}#{@query.new_record? ? 1 : 0}"
  end
end
