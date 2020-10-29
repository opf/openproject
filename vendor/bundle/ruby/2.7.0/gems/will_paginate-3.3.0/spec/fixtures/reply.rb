class Reply < ActiveRecord::Base
  scope :recent, lambda {
    where(['replies.created_at > ?', 15.minutes.ago]).
      order('replies.created_at DESC')
  }

  validates_presence_of :content
end
