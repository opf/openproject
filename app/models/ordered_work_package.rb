class OrderedWorkPackage < ApplicationRecord
  belongs_to :query
  belongs_to :work_package

  acts_as_list
  validates_numericality_of :position
end
