# frozen_string_literal: true

class Mngt::UserProfile < ApplicationRecord
  self.table_name = "mngt_user_profiles"

  belongs_to :user

  validates :company_slug, presence: true
end
