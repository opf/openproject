class HotList < ApplicationRecord
  validates_presence_of :title
  has_many :items, class_name: 'HotItem'

  def work_packages
    WorkPackage.where(id: items.order(:position).select(:work_package_id))
  end
end
