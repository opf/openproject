module LdapGroups
  class Membership < ApplicationRecord
    belongs_to :user
    belongs_to :group,
               class_name: "::LdapGroups::SynchronizedGroup",
               counter_cache: :users_count

    validates_uniqueness_of :user_id, scope: :group_id
  end
end
