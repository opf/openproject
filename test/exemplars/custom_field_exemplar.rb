class CustomField < ActiveRecord::Base
  generator_for :name, :method => :next_name
  generator_for :field_format => 'string'

  def self.next_name
    @last_name ||= 'CustomField0'
    @last_name.succ!
    @last_name
  end
end
