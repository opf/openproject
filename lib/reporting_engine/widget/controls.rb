class Widget::Controls < Widget::Base
  extend ProactiveAutoloader

  def cache_key
    "#{super}#{@subject.new_record? ? 1 : 0}"
  end
end
