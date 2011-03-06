class Meeting < ActiveRecord::Base
  unloadable
  
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_one :agenda, :dependent => :destroy, :class_name => 'MeetingAgenda'
  has_one :minutes, :dependent => :destroy, :class_name => 'MeetingMinutes'
  has_many :participants, :dependent => :destroy, :class_name => 'MeetingParticipant'
  
  accepts_nested_attributes_for :participants
  
  validates_presence_of :title, :start_time
  
  def self.find_time_sorted(*args)
    by_start_year_month_date = ActiveSupport::OrderedHash.new
    self.find(*args).group_by(&:start_year).each do |year,objs|
      by_start_year_month_date[year] = ActiveSupport::OrderedHash.new
      objs.group_by(&:start_month).each do |month,objs|
        by_start_year_month_date[year][month] = ActiveSupport::OrderedHash.new
        objs.group_by(&:start_date).each do |date,objs|
          by_start_year_month_date[year][month][date] = objs.sort_by {|m| m.start_time}.reverse
        end
      end
    end
    by_start_year_month_date
  end
  
  def start_date
    # the text_field + calendar_for form helpers expect a Date
    start_time.to_date
  end
  
  def start_month
    start_time.month
  end
  
  def start_year
    start_time.year
  end
  
  def end_time
    start_time + duration.hours
  end
  
  def to_s
    title
  end
  
  def recipients
    participants.collect(&:mail)
  end
  
  protected
  
  def after_initialize
    # set defaults
    self.start_time ||= Date.tomorrow + 10.hours
    self.duration   ||= 1
  end
end
