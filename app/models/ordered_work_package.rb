class OrderedWorkPackage < ApplicationRecord
  belongs_to :query
  belongs_to :work_package

  acts_as_list scope: :query, top_of_list: 0
end
