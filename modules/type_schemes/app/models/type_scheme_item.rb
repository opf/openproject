class TypeSchemeItem < ApplicationRecord
  self.table_name = "type_scheme_items"
  belongs_to :scheme, class_name: "TypeScheme", inverse_of: :items
  belongs_to :type
end
