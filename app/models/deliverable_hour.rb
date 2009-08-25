class DeliverableHour < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :rate, :class_name => "HourlyRate", :foreign_key => 'rate_id'
  
  def self.new(params={})
    unless params[:rate_id] || params[:rate]
      new_user_id = params.delete(:user).id if params[:user]
      new_user_id ||= params.delete(:user_id)
      
      if new_user_id
        project_id = params[:deliverable].project_id if params[:deliverable]
        project_id || Deliverable.find(params[:deliverable_id]).project_id if params[:deliverable_id]
        
        params[:rate] = HourlyRate.current_rate(new_user_id, project_id) if project_id
      end
      params[:rate] = HourlyRate.default unless params[:rate]
    end

    super(params)
  end


  def user
    rate.user
  end
  
  def user=(new_user)
    if self.deliverable
      self.rate = HourlyRate.current_rate(new_user.id, self.deliverable.project.id)
    else
      self.rate = HourlyRate.current_rate(new_user.id, nil)
    end
  end
  
  def user_id
    rate.user_id
  end
  
  def user_id=(new_user_id)
    if self.deliverable
      self.rate = HourlyRate.current_rate(new_user_id, self.deliverable.project.id)
    else
      self.rate = HourlyRate.current_rate(new_user_id, nil)
    end
  end
  
  def costs
    rate.rate && hours ? rate.rate * hours : 0.0
  end
  
  def can_view_costs?(usr, project)
    user = rate.user if rate

    usr.allowed_to?(:view_all_rates, project) || (user && usr == user && user.allowed_to?(:view_own_rate, project))
  end
end