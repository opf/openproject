class IssuePriority < Enumeration
  generator_for :name, :method => :next_name
  generator_for :type => 'IssuePriority'

  def self.next_name
    @last_name ||= 'IssuePriority0'
    @last_name.succ!
    @last_name
  end
end
