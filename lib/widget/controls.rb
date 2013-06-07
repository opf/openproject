class Widget::Controls < Widget::Base

  def cache_key
    "#{super}#{@subject.new_record? ? 1 : 0}"
  end
end
