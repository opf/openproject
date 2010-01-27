class WikiPage < ActiveRecord::Base
  generator_for :title, :method => :next_title
  generator_for :wiki, :method => :generate_wiki

  def self.next_title
    @last_title ||= 'AWikiPage'
    @last_title.succ!
    @last_title
  end

  def self.generate_wiki
    Wiki.generate!
  end
end
