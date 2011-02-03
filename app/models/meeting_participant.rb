class MeetingParticipant < ActiveRecord::Base
  unloadable
  
  belongs_to :meeting
  belongs_to :user
  
  def name
    user.present? ? user.name : self.name
  end
  
  alias :to_s :name
end
