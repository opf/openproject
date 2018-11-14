require 'net/ldap'
require 'net/ldap/dn'

module LdapGroups
  class SynchronizedGroup < ActiveRecord::Base
    belongs_to :group
    belongs_to :auth_source
    has_many :users,
             class_name: '::LdapGroups::Membership',
             foreign_key: 'group_id'

    validates_presence_of :entry
    validates_presence_of :group
    validates_presence_of :auth_source

    before_destroy :remove_all_members

    def dn
      ::OpenProject::LdapGroups.group_dn(escaped_entry)
    end

    ##
    # Add a set of new members to the internal group
    def add_members!(new_users)
      self.class.transaction do
        users << new_users.map { |u| Membership.new group: self, user: u }
        group.users << new_users
      end
    end

    ##
    # Remove a set of users from the internal group
    def remove_members!(users_to_remove)
      self.class.transaction do
        user_ids = users_to_remove.pluck(:user_id)
        users_to_remove.destroy_all

        # We don't have access to the join table
        # so we need to ensure we delete the users that are still present in the group
        # since users MAY want to remove users manually
        user_ids.each { |id| remove_from_actual_group(id) }
      end
    end

    def escaped_entry
      Net::LDAP::DN.escape(entry)
    end

    private

    def remove_from_actual_group(id)
      group.users.delete(id)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "Tried to remove user##{id} from #{group.name}, but it was already removed."
    end

    def remove_all_members
      remove_members!(users)
    end
  end
end
