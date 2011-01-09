class Meeting < ActiveRecord::Base
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_one :agenda, :dependent => :destroy, :class_name => 'MeetingAgenda'
  has_one :minutes, :dependent => :destroy, :class_name => 'MeetingMinutes'
  has_many :participants, :dependent => :destroy, :class_name => 'MeetingParticipant'
end
