class Repository::Subversion < Repository
  generator_for :type, :method => 'Subversion'
  generator_for :url, :method => :next_url

  def self.next_url
    @last_url ||= 'file:///test/svn'
    @last_url.succ!
    @last_url
  end

end
