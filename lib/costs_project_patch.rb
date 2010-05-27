require_dependency 'project'

module CostsProjectPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      has_many :cost_objects, :dependent => :destroy
      has_many :rates, :class_name => 'HourlyRate'
      
      has_many :member_groups, :class_name => 'Member', 
                               :include => :principal,
                               :conditions => "#{Principal.table_name}.type='Group'"
      has_many :groups, :through => :member_groups, :source => :principal
      
      class << self
        alias_method_chain :allowed_to_condition, :inheritance
      end
    end

  end

  module ClassMethods
    def allowed_to_condition_with_inheritance(user, permission, options={})
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
          if Role.non_member.allowed_to?(permission) && !options[:member]
            statements << "#{Project.table_name}.is_public = #{connection.quoted_true}"
          end
          user_options = options.reject{|k,v| k!=:for}
          allowed_project_ids = Project.all(:conditions => Project.visible_by(user), :include => :enabled_modules).select do |p|
            user.allowed_to?(permission, p, user_options)
          end.collect(&:id)
          statements << "#{Project.table_name}.id IN (#{allowed_project_ids.join(',')})" if allowed_project_ids.any?
        else
          if Role.anonymous.allowed_to?(permission) && !options[:member]
            # anonymous user allowed on public project
            statements << "#{Project.table_name}.is_public = #{connection.quoted_true}"
          end 
        end
      end
      statements.empty? ? base_statement : "((#{base_statement}) AND (#{statements.join(' OR ')}))"
    end
  end
end

Project.send(:include, CostsProjectPatch)