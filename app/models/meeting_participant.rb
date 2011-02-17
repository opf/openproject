class MeetingParticipant < ActiveRecord::Base
  unloadable
  
  belongs_to :meeting
  belongs_to :user
  
  named_scope :invited, :conditions => {:invited => true}
  named_scope :attended, :conditions => {:attended => true}
  
  def name
    user.present? ? user.name : self.name
  end
  
  alias :to_s :name
end
