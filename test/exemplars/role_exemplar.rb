class Role < ActiveRecord::Base
  generator_for :name, :method => :next_name

  def self.next_name
    @last_name ||= 'Role0'
    @last_name.succ!
  end
end
