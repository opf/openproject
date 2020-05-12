module LdapGroups
  class Membership < ApplicationRecord
    belongs_to :user
    belongs_to :group,
               class_name: '::LdapGroups::SynchronizedGroup',
               foreign_key: 'group_id',
               counter_cache: :users_count
  end
end
