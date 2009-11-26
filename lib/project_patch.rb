require_dependency 'project'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Cost Object
module ProjectPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      has_many :cost_objects
      has_many :rates, :class_name => 'HourlyRate'
      
      has_many :member_groups, :class_name => 'Member', 
                               :include => :principal,
                               :conditions => "#{Principal.table_name}.type='Group'"
      has_many :groups, :through => :member_groups, :source => :principal
      
      unless singleton_methods.include? "allowed_to_condition_without_inheritance"
        class << self
          #alias_method_chain :allowed_to_condition, :inheritance
        end
      end
      
    end

  end

  module ClassMethods
    def allowed_to_condition_with_inheritance(user, permission, options={})
      # we just added to user parameter to the calls to role.allowed_to?

      statements = []
      base_statement = "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
      if perm = Redmine::AccessControl.permission(permission)
        unless perm.project_module.nil?
          # If the permission belongs to a project module, make sure the module is enabled
          base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
        end
      end
      if options[:project]
        project_statement = "#{Project.table_name}.id = #{options[:project].id}"
        project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
        base_statement = "(#{project_statement}) AND (#{base_statement})"
      end
      if user.admin?
        # no restriction
      else
        statements << "1=0"
        if user.logged?
          if Role.non_member.allowed_to?(permission, user) && !options[:member]
            statements << "#{Project.table_name}.is_public = #{connection.quoted_true}"
          end
          allowed_project_ids = user.memberships.select {|m| m.roles.detect {|role| role.allowed_to?(permission, user)}}.collect {|m| m.project_id}
          statements << "#{Project.table_name}.id IN (#{allowed_project_ids.join(',')})" if allowed_project_ids.any?
        else
          if Role.anonymous.allowed_to?(permission, user) && !options[:member]
            # anonymous user allowed on public project
            statements << "#{Project.table_name}.is_public = #{connection.quoted_true}"
          end 
        end
      end
      statements.empty? ? base_statement : "((#{base_statement}) AND (#{statements.join(' OR ')}))"
    end

  end

  module InstanceMethods
  end
end
