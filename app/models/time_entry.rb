class TimeEntry < ActiveRecord::Base
  # could have used polymorphic association
  # project association here allows easy loading of time entries at project level with one database trip
  belongs_to :project
  belongs_to :issue
  belongs_to :user
  belongs_to :activity, :class_name => 'TimeEntryActivity', :foreign_key => 'activity_id'
  
  attr_protected :project_id, :user_id, :tyear, :tmonth, :tweek

  acts_as_customizable
  acts_as_journalized :event_title => Proc.new {|o| "#{l_hours(o.hours)} (#{(o.issue || o.project).event_title})"},
                :event_url => Proc.new {|o| {:controller => 'timelog', :action => 'index', :project_id => o.project, :issue_id => o.issue}},
                :event_author => :user,
                :event_description => :comments

  validates_presence_of :user_id, :activity_id, :project_id, :hours, :spent_on
  validates_numericality_of :hours, :allow_nil => true, :message => :invalid
  validates_length_of :comments, :maximum => 255, :allow_nil => true
  
  named_scope :visible, lambda {|*args| { 
    :include => :project,
    :conditions => Project.allowed_to_condition(args.first || User.current, :view_time_entries) 
  }}

  def after_initialize
    if new_record? && self.activity.nil?
      if default_activity = TimeEntryActivity.default
        self.activity_id = default_activity.id
      end
      self.hours = nil if hours == 0
    end
  end
  
  def before_validation
    self.project = issue.project if issue && project.nil?
  end
  
  def validate
    errors.add :hours, :invalid if hours && (hours < 0 || hours >= 1000)
    errors.add :project_id, :invalid if project.nil?
    errors.add :issue_id, :invalid if (issue_id && !issue) || (issue && project!=issue.project)
  end
  
  def hours=(h)
    write_attribute :hours, (h.is_a?(String) ? (h.to_hours || h) : h)
  end
  
  # tyear, tmonth, tweek assigned where setting spent_on attributes
  # these attributes make time aggregations easier
  def spent_on=(date)
    super
    if spent_on.is_a?(Time)
      self.spent_on = spent_on.to_date
    end
    self.tyear = spent_on ? spent_on.year : nil
    self.tmonth = spent_on ? spent_on.month : nil
    self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
  end
  
  # Returns true if the time entry can be edited by usr, otherwise false
  def editable_by?(usr)
    (usr == user && usr.allowed_to?(:edit_own_time_entries, project)) || usr.allowed_to?(:edit_time_entries, project)
  end
  
  # TODO: remove this method in 1.3.0
  def self.visible_by(usr)
    ActiveSupport::Deprecation.warn "TimeEntry.visible_by is deprecated and will be removed in Redmine 1.3.0. Use the visible scope instead."
    with_scope(:find => { :conditions => Project.allowed_to_condition(usr, :view_time_entries) }) do
      yield
    end
  end

  def self.earilest_date_for_project(project=nil)
    finder_conditions = ARCondition.new(Project.allowed_to_condition(User.current, :view_time_entries))
    if project
      finder_conditions << ["project_id IN (?)", project.hierarchy.collect(&:id)]
    end
    TimeEntry.minimum(:spent_on, :include => :project, :conditions => finder_conditions.conditions)
  end

  def self.latest_date_for_project(project=nil)
    finder_conditions = ARCondition.new(Project.allowed_to_condition(User.current, :view_time_entries))
    if project
      finder_conditions << ["project_id IN (?)", project.hierarchy.collect(&:id)]
    end
    TimeEntry.maximum(:spent_on, :include => :project, :conditions => finder_conditions.conditions)
  end
end
