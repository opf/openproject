class Rate < ActiveRecord::Base
  unloadable
  
  validates_numericality_of :rate, :allow_nil => false, :message => :activerecord_error_invalid
end