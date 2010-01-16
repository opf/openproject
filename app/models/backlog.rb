class Backlog < ActiveRecord::Base
  unloadable
  belongs_to :version
  has_many   :items

  def description
    version.description
  end

  def description=(value)
    version.description = value
  end

  def end_date
    version.effective_date
  end
  
  def end_date=(value)
    version.effective_date = value
  end
  
  def is_main?
    # Used by generate_chart_data.rake because I'm expecting
    # to create real backlogs in the future to represent
    # the Main Backlogs of every project.
    false  
  end
  
  def name
    version.name
  end
  
  def name=(value)
    version.name = value
  end

  def self.delete_backlog(version)
    find_by_version_id(version.id).destroy
  end

  def eta
    return "no start dt." if start_date.nil?
    return "no velocity"  if velocity==0
    return "no due date"  if end_date.nil?
        
    weekdays = start_date.weekdays_until(end_date)
    
    # Get average daily velocity
    average_vel = velocity.to_f/weekdays.to_f
    
    # Divide total points in backlog by daily velocity (Quotient is number of days until completed)
    days_to_eta = (total_points/average_vel).ceil
    
    # Get the date that is <quotient> days from start_date
    days_to_eta.weekdays_from(start_date).strftime("%Y-%m-%d")
  end
  

  def self.find_by_project(project)
    find(:all, :include => :version, :conditions => "versions.project_id=#{project.id}", :order => "versions.effective_date ASC, versions.id ASC")
  end
  
  def self.update(params)
    backlog = find(params[:id])
    backlog.version.update_attributes! params[:version]
    backlog.update_attributes! params[:backlog]
    backlog
  end
  
  def self.remove_with_version(version)
    find_by_version_id(version.id).destroy
  end
  
  def self.update_from_version(version)
    backlog = find_by_version_id(version.id) || Backlog.new()
    backlog.version_id = version.id
    backlog.save
  end
  
  def start_date
    s = super
    s.to_date if s.class==Time
  end
  
  def total_points
    total_points = 0
    items.each do |item|
      total_points += item.points unless item.points.nil? || item.parent_id!=0
    end
    total_points
  end
  
  
end
