class Rate < ActiveRecord::Base
  unloadable
  
  has_many :deliverable_hours
  has_many :time_entries
  belongs_to :user
  belongs_to :project
  
  validates_numericality_of :hourly_price, :allow_nil => false, :message => :activerecord_error_invalid
end

class GenericRate < Rate
end