class MyProjectsOverview < ActiveRecord::Base
  unloadable

  DEFAULTS = {
    "left" => ["wiki", "projectdetails", "issuetracking"].to_yaml,
    "right" => ["members", "news"].to_yaml,
    "top" => [].to_yaml,
    "hidden" => [].to_yaml }

  after_initialize do
    hs = attributes
    DEFAULTS.each_pair {|k, v| update_attribute(k, v) if hs[k].blank? }
  end

  serialize :top, Array
  serialize :left, Array
  serialize :right, Array
  serialize :hidden, Array
  belongs_to :project

  acts_as_attachable :delete_permission => :edit_project, :view_permission => :view_project

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

  def attachments_visible?(user)
    true
  end
end
