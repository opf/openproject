class Group < Principal
  generator_for :lastname, :method => :next_lastname

  def self.next_lastname
    @last_lastname ||= 'Group'
    @last_lastname.succ!
    @last_lastname
  end

end
