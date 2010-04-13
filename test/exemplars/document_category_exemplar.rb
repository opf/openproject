class DocumentCategory < Enumeration
  generator_for :name, :method => :next_name
  generator_for :type => 'DocumentCategory'

  def self.next_name
    @last_name ||= 'DocumentCategory0'
    @last_name.succ!
    @last_name
  end
end
