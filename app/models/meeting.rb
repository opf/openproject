class Meeting < ActiveRecord::Base
  unloadable
  
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_one :agenda, :dependent => :destroy, :class_name => 'MeetingAgenda'
  has_one :minutes, :dependent => :destroy, :class_name => 'MeetingMinutes'
  has_many :participants, :dependent => :destroy, :class_name => 'MeetingParticipant'
  
  validates_presence_of :title
  
  def start_date
    # the text_field + calendar_for form helpers expect a Date
    start_time.to_date if start_time.present?
  end
  
  protected
  
  def after_initialize
    # set defaults
    self.start_time ||= Date.tomorrow + 10.hours
    self.duration   ||= 1
  end
end
