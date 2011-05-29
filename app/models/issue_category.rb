class IssueCategory < ActiveRecord::Base
  belongs_to :project
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  has_many :issues, :foreign_key => 'category_id', :dependent => :nullify
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 30
  
  alias :destroy_without_reassign :destroy
  
  # Destroy the category
  # If a category is specified, issues are reassigned to this category
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(IssueCategory) && reassign_to.project == self.project
      Issue.update_all("category_id = #{reassign_to.id}", "category_id = #{id}")
    end
    destroy_without_reassign
  end
  
  def <=>(category)
    name <=> category.name
  end
  
  def to_s; name end
end
