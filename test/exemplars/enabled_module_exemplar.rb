class EnabledModule < ActiveRecord::Base
  generator_for :name, :method => :next_name

  def self.next_name
    @last_name ||= 'module_001'
    @last_name.succ!
    @last_name
  end

end
