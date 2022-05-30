class HotItem < ApplicationRecord
  belongs_to :hot_list
  belongs_to :work_package
  has_one :hot_board, through: :hot_list

  validates_presence_of :hot_list, :work_package
end
