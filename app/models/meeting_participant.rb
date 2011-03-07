class MeetingParticipant < ActiveRecord::Base
  unloadable
  
  belongs_to :meeting
  belongs_to :user
  
  named_scope :invited, :conditions => {:invited => true}
  named_scope :attended, :conditions => {:attended => true}
  
  after_create :add_participant_as_watcher
  
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
  
  private
  
  def add_participant_as_watcher
    meeting.add_watcher(user)
  end
end
