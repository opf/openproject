# A CostObject is an item that is created as part of the project.  These items
# contain a collection of work packages.
class CostObject < ActiveRecord::Base
  unloadable

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :project
  has_many :work_packages, :dependent => :nullify

  has_many :cost_entries, :through => :work_packages
  has_many :time_entries, :through => :work_packages

  include ActiveModel::ForbiddenAttributesProtection

  acts_as_attachable :after_remove => :attachment_removed

  acts_as_journalized :event_type => 'cost-object',
    :event_title => Proc.new {|o| "#{l(:label_cost_object)} ##{o.journaled.id}: #{o.subject}"},
    :event_url => Proc.new {|o| {:controller => 'cost_objects', :action => 'show', :id => o.journaled.id}},
    :activity_type => superclass.plural_name,
    :activity_find_options => {:include => [:project, :author]},
    :activity_timestamp => "#{table_name}.updated_on",
    :activity_author_key => :author_id,
    :activity_permission => :view_cost_objects

  validates_presence_of :subject, :project, :author, :kind
  validates_length_of :subject, :maximum => 255
  validates_length_of :subject, :minimum => 1

  User.before_destroy do |user|
    CostObject.replace_author_with_deleted_user user
  end

  def initialize(attributes = nil)
    super
    self.author = User.current if self.new_record?
  end

  def copy_from(arg)
    if !arg.is_a?(Hash)
      #turn args into an attributes hash if it is not already (which is the case when called from VariableCostObject)
      arg = (arg.is_a?(CostObject) ? arg : self.class.find(arg)).attributes.dup
    end
    arg.delete("id")
    self.type = arg.delete("type")
    self.attributes = arg
  end

  # Wrap type column to make it usable in views (especially in a select tag)
  def kind
    self[:type]
  end

  def kind=(type)
    self[:type] = type
  end

  # Assign all the work_packages with +version_id+ to this Cost Object
  def assign_work_packages_by_version(version_id)
    version = Version.find_by_id(version_id)
    return 0 if version.nil? || version.fixed_work_packages.blank?

    version.fixed_work_packages.each do |work_package|
      work_package.update_attribute(:cost_object_id, self.id)
    end

    return version.fixed_work_packages.size
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

  # Budget of labor.  Virtual accessor that is overriden by subclasses.
  def labor_budget
    0.0
  end

  # Budget of material, i.e. all costs besides labor costs.  Virtual accessor that is overriden by subclasses.
  def material_budget
    0.0
  end

  def budget
    material_budget + labor_budget
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
    return "cost_object"
  end

  def self.replace_author_with_deleted_user(user)
    substitute = DeletedUser.first

    self.update_all ['author_id = ?', substitute.id], ['author_id = ?', user.id]
  end
end
