# frozen_string_literal: true

module LdapDepartments
  class Membership < ApplicationRecord
    belongs_to :user
    belongs_to :synchronized_department,
               class_name: "::LdapDepartments::SynchronizedDepartment",
               counter_cache: :users_count

    validates :user_id, uniqueness: { scope: :synchronized_department_id }
  end
end
