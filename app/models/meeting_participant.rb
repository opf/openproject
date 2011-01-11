class MeetingParticipant < ActiveRecord::Base
  unloadable
  
  belongs_to :meeting
  belongs_to :user
end
