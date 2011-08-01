# A CostObject is an item that is created as part of the project.  These items
# contain a collection of issues.
class CostObject < ActiveRecord::Base
  unloadable

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :project
  has_many :issues, :dependent => :nullify
  
  has_many :cost_entries, :through => :issues
  has_many :time_entries, :through => :issues
  
  attr_protected :author
  
  acts_as_attachable :after_remove => :attachment_removed
  
  acts_as_event :title => Proc.new {|o| "#{l(:label_cost_object)} ##{o.id}: #{o.subject}"},
                :url => Proc.new {|o| {:controller => 'cost_objects', :action => 'show', :id => o.id}}
  
  if respond_to? :acts_as_journalized
    acts_as_journalized :activity_find_options => {:include => [:project, :author]},
                        :activity_timestamp => "#{table_name}.updated_on",
                        :activity_author_key => :author_id
  else
    acts_as_activity_provider :find_options => {:include => [:project, :author]},
                              :timestamp => "#{table_name}.updated_on",
                              :author_key => :author_id
  end
  
  validates_presence_of :subject, :project, :author, :kind
  validates_length_of :subject, :maximum => 255
  validates_length_of :subject, :minimum => 1
  
  
  def before_validation
    self.author_id = User.current.id if self.new_record?
  end
  
  def before_destroy
    issues.all.each do |i|
      result = i.update_attributes({:cost_object => nil})
      return false unless result
    end
  end
  
  def attributes=(attrs)
    # Remove any attributes which can not be assigned.
    # This is to protect from exceptions during change of cost object type
    attrs.delete_if{|k, v| !self.respond_to?("#{k}=")} if attrs.is_a?(Hash)
    
    super(attrs)
  end
  
  def copy_from(arg)
    cost_object = arg.is_a?(CostObject) ? arg : CostObject.find(arg)
    self.attributes = cost_object.attributes.dup
  end
  
  # Wrap type column to make it usable in views (especially in a select tag)
  def kind
    self[:type]
  end
  
  def kind=(type)
    self[:type] = type
  end
  
  # Assign all the issues with +version_id+ to this Cost Object
  def assign_issues_by_version(version_id)
    version = Version.find_by_id(version_id)
    return 0 if version.nil? || version.fixed_issues.blank?
    
    version.fixed_issues.each do |issue|
      issue.update_attribute(:cost_object_id, self.id)
    end
    
    return version.fixed_issues.size
  end
  
  # Change the Cost Object type to another type. Valid types are
  #
  # * FixedCostObject
  # * VariableCostObject
  def change_type(to)
    if [FixedCostObject.name, VariableCostObject.name].include?(to)
      self.type = to
      self.save!
      return CostObject.find(self.id)
    else
      return self
    end
  end
  
  # Amount spent.  Virtual accessor that is overriden by subclasses.
  def spent
    0
  end
  
  def spent_for_display
    # FIXME: Remove this function
    spent
  end
  
  # Budget of labor.  Virtual accessor that is overriden by subclasses.
  def labor_budget
    0.0
  end
  
  def labor_budget_for_display
    # FIXME: Remove this function
    labor_budget
  end
    
  # Budget of material, i.e. all costs besides labor costs.  Virtual accessor that is overriden by subclasses.
  def material_budget
    0.0
  end
  
  def material_budget_for_display
    # FIXME: Remove this function
    material_budget
  end
  
  def budget
    material_budget + labor_budget
  end
  
  def budget_for_display
    # FIXME: Remove this function
    budget
  end
  
  def status
    # this just returns the symbol for I18N
    if project_manager_signoff
      client_signoff ? :label_status_finished : :label_status_awaiting_client
    else
      client_signoff ? :label_status_awaiting_client : :label_status_in_progress
    end
  end
  
  # Label of the current type for display in GUI.  Virtual accessor that is overriden by subclasses.
  def type_label
    return l(:label_cost_object)
  end
  
  # Amount of the budget spent.  Expressed as as a percentage whole number
  def budget_ratio
    return 0.0 if self.budget.nil? || self.budget == 0.0
    return ((self.spent / self.budget) * 100).round
  end
  
  def css_classes
    return "issue cost_object"
  end
  
end
