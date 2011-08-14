class MyProjectsOverview < ActiveRecord::Base
  serialize :top, Array
  serialize :left, Array
  serialize :right, Array
  serialize :hidden, Array

  def save_custom_element(name, title, new_content)
    el = custom_elements.detect {|x| x.first == name}
    return unless el
    el[1] = title
    el[2] = new_content
    save
  end

  def new_custom_element
    idx = custom_elements.any? ? custom_elements.sort.last.first.next : "a"
    [idx, l(:label_custom_text), "h2. #{l(:info_custom_text)}"]
  end

  def elements
    top + left + right + hidden
  end

  def custom_elements
    elements.select {|x| x.respond_to? :to_ary }
  end
end
