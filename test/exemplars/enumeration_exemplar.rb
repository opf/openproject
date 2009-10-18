class Enumeration < ActiveRecord::Base
  generator_for :name, :method => :next_name
  generator_for :type => 'TimeEntryActivity'

  def self.next_name
    @last_name ||= 'Enumeration0'
    @last_name.succ!
    @last_name
  end
end
