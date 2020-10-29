class Book < ActiveRecord::Base
  belongs_to :topic, inverse_of: :books
  belongs_to :tag, foreign_key: [:tag_id, :parent_id]

  has_many :chapters, inverse_of: :book
  has_many :discounts, as: :discountable
  has_many :end_notes, inverse_of: :book
  enum status: [:draft, :published] if ENV['AR_VERSION'].to_f >= 4.1
end
