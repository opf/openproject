class Document < ActiveRecord::Base
  generator_for :title, :method => :next_title

  def self.next_title
    @last_title ||= 'Document001'
    @last_title.succ!
    @last_title
  end
end
