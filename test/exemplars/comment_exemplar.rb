class Comment < ActiveRecord::Base
  generator_for :commented, :method => :generate_news
  generator_for :author, :method => :generate_author
  generator_for :comments => 'What great news this is.'

  def self.generate_news
    News.generate!
  end

  def self.generate_author
    User.generate_with_protected!
  end
end
