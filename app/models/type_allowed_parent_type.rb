# frozen_string_literal: true

class TypeAllowedParentType < ApplicationRecord
  belongs_to :type
  belongs_to :parent_type, class_name: "Type"
end
