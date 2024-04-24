class NonWorkingDay < ApplicationRecord
  validates :name, :date, presence: true
  validates :date, uniqueness: true
end
