#-- encoding: UTF-8
class Category < ActiveRecord::Base
  acts_as_nested_set
  
  def to_s
    name
  end
  
  def recurse &block
    block.call self, lambda{
      self.children.each do |child|
        child.recurse &block
      end
    }
  end
end