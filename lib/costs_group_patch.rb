require_dependency 'principal'
require_dependency 'group'

module CostsGroupPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      has_many :groups_users, :class_name => 'GroupUser', :dependent => :destroy,
        :after_add => :group_user_added,
        :after_remove => :group_user_removed

      has_many :users, :through => :groups_users,
        :after_add => :user_added,
        :after_remove => :user_removed
    end

  end

  module InstanceMethods
    def change_membership_type(user, membership_type)
      group_user = groups_users.detect{|gu| gu.user_id == user.id}
      raise ArgumentError("#{user.name} is not a member of group #{self}") unless group_user

      group_user.update_attributes!(:membership_type => membership_type)
      
      members.each do |member|
        MemberRole.find(:all,
          :include => :member,
          :conditions => ["#{Member.table_name}.user_id = ? AND #{MemberRole.table_name}.inherited_from IN (?)", user.id, member.member_role_ids]).each do |role|
            role.update_attributes!(:membership_type => membership_type)
          end
      end
    end
    
    def group_user_added(group_user)
      user = group_user.user
      membership_type = group_user.membership_type
      
      members.each do |member|
        user_member = Member.find_by_project_id_and_user_id(member.project_id, user.id) || Member.new(:project_id => member.project_id, :user_id => user.id)
        member.member_roles.each do |member_role|
          user_member.member_roles << MemberRole.new(:role => member_role.role, :inherited_from => member_role.id, :membership_type => membership_type)
        end
        user_member.save!
      end
    end
    
    def group_user_removed(group_user)
      user_removed(group_user.user)
    end
  end
end

Group.send(:include, CostsGroupPatch)