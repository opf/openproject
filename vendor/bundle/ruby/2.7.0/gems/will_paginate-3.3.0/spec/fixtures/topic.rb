class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy
  belongs_to :project

  scope :mentions_activerecord, lambda {
    where(['topics.title LIKE ?', '%ActiveRecord%'])
  }
end
