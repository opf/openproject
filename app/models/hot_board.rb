class HotBoard < ApplicationRecord
  has_many :lists, class_name: 'HotList'
  validates_presence_of :title
end
