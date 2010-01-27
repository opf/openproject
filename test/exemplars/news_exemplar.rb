class News < ActiveRecord::Base
  generator_for :title, :method => :next_title
  generator_for :description, :method => :next_description

  def self.next_title
    @last_title ||= 'A New Item'
    @last_title.succ!
    @last_title
  end

  def self.next_description
    @last_description ||= 'Some content here'
    @last_description.succ!
    @last_description
  end
end
