class WikiContent < ActiveRecord::Base
  generator_for :text => 'Some content'
  generator_for :page, :method => :generate_page

  def self.generate_page
    WikiPage.generate!
  end
end
