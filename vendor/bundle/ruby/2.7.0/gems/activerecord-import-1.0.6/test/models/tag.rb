class Tag < ActiveRecord::Base
  self.primary_keys = :tag_id, :publisher_id unless ENV["SKIP_COMPOSITE_PK"]
  has_many :books, inverse_of: :tag
end
