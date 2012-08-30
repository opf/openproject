#-- encoding: UTF-8
class Company < ActiveRecord::Base
  attr_protected :rating
  set_sequence_name :companies_nonstd_seq

  validates_presence_of :name

  validate :rating_does_not_equal_two

  def rating_does_not_equal_two
    errors.add('rating', 'rating should not be 2') if rating == 2
  end  
end