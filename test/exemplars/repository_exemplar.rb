class Repository < ActiveRecord::Base
  generator_for :type => 'Subversion'
  generator_for :url, :method => :next_url

  def self.next_url
    @last_url ||= 'file:///test/svn'
    @last_url.succ!
    @last_url
  end

end
