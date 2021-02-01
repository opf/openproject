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
    validates_associated :group
    validates_presence_of :auth_source

    before_destroy :remove_all_members

    ##
    # Add a set of new members to the synchronized group as well as the internal group.
    #
    # @param new_users [Array<User> | Array<Integer>] Users (or User IDs) to add to the group.
    def add_members!(new_users)
      return if new_users.empty?

      self.class.transaction do
        # create synchronized group memberships
        memberships = new_users.map { |user| { group_id: self.id, user_id: user_id(user) } }
        # Bulk insert the memberships to improve performance
        ::LdapGroups::Membership.insert_all memberships

        # add users to users collection of internal group
        group.add_members! new_users
      end
    end

    ##
    # Remove a set of users from the synchronized group as well as the internal group.
    #
    # @param users_to_remove [Array<User> | Array<Integer>] Users (or User IDs) to remove from the group.
    def remove_members!(users_to_remove)
      return if users_to_remove.empty?

      self.class.transaction do
        # 1) Delete synchronized group MEMBERSHIPS from collection.
        # 2) Remove users from users collection of internal group.
        if users_to_remove.first.is_a? User
          users.delete users.where(user: users_to_remove).select(:id)
          group.users.delete users_to_remove
        elsif users_to_remove.first.is_a? Integer
          users.delete users.where(user_id: users_to_remove).select(:id)
          group.users.delete group.users.where(id: users_to_remove).select(:id)
        else
          raise ArgumentError, "Expected collection of Users or User IDs, got collection of #{users_to_remove.map(&:class).map(&:name).uniq.join(", ")}"
        end
      end
    end

    private

    def user_id(user)
      if user.is_a? Integer
        user
      elsif user.is_a? User
        user.id
      else
        raise ArgumentError, "Expected User or User ID (Integer) but got #{user}"
      end
    end

    def remove_all_members
      remove_members! User.find(users.pluck(:user_id))
    end
  end
end
