class IssueStatus < ActiveRecord::Base
  generator_for :name, :method => :next_name

  def self.next_name
    @last_name ||= 'Status 0'
    @last_name.succ!
    @last_name
  end
end
