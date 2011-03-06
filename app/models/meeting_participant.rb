class MeetingParticipant < ActiveRecord::Base
  unloadable
  
  belongs_to :meeting
  belongs_to :user
  
  named_scope :invited, :conditions => {:invited => true}
  named_scope :attended, :conditions => {:attended => true}
  
  def name
    user.present? ? user.name : self.name
  end
  
  def mail
    user.present? ? user.mail : self.mail
  end
  
  def <=>(participant)
    self.to_s.downcase <=> participant.to_s.downcase
  end
  
  alias :to_s :name
end
