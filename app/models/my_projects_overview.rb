class MyProjectsOverview < ActiveRecord::Base
  serialize :top, Array
  serialize :left, Array
  serialize :right, Array
  serialize :hidden, Array

  def save_custom_element(name, new_content)
    el = custom_elements.detect {|x| x.first == name}
    return unless el
    el.pop
    el << new_content
    save
  end

  def new_custom_element
    idx = custom_elements.any? ? custom_elements.sort.last.first.next : "a"
    [idx, "h2. #{l(:info_custom_text)}"]
  end

  def elements
    top + left + right + hidden
  end

  def custom_elements
    elements.select {|x| x.respond_to? :to_ary }
  end
end
