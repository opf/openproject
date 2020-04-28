require 'net/ldap'
require 'net/ldap/dn'

module LdapGroups
  class SynchronizedGroup < ApplicationRecord
    belongs_to :group

    belongs_to :auth_source

    belongs_to :filter,
               class_name: '::LdapGroups::SynchronizedFilter',
               foreign_key: :filter_id

    has_many :users,
             class_name: '::LdapGroups::Membership',
             dependent: :delete_all,
             foreign_key: 'group_id'

    validates_presence_of :dn
    validates_presence_of :group
    validates_presence_of :auth_source

    before_destroy :remove_all_members

    ##
    # Add a set of new members to the internal group
    def add_members!(new_users)
      self.class.transaction do
        users << new_users.map { |u| Membership.new group: self, user: u }
        group.add_members!(new_users)
      end
    end

    ##
    # Remove a set of users from the internal group
    def remove_members!(users_to_remove)
      self.class.transaction do
        user_ids = users_to_remove.pluck(:user_id)

        # We don't have access to the join table
        # so we need to ensure we delete the users that are still present in the group
        # since users MAY want to remove users manually
        group.users.where(id: user_ids).destroy_all
      end
    end

    private

    def remove_all_members
      remove_members!(users)
    end
  end
end
