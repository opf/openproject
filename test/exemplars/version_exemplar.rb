class Version < ActiveRecord::Base
  generator_for :name, :method => :next_name
  generator_for :status => 'open'
  
  def self.next_name
    @last_name ||= 'Version 1.0.0'
    @last_name.succ!
    @last_name
  end

end
