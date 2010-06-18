class Journal < ActiveRecord::Base
  self.abstract_class = true
  
  belongs_to :user
  serialize :details
  
  attr_accessor :indice
  
  before_save :check_for_empty_journal

  def check_for_empty_journal
    # Do not save an empty journal
    !(details.empty? && notes.blank?)
  end
end
