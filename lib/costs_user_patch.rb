require_dependency 'project'

require_dependency 'principal'
require_dependency 'user'

module CostsUserPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      has_many :groups_users, :class_name => 'GroupUser', :dependent => :destroy,
        :after_add => Proc.new {|user, group_user| group_user.group.user_added(user)},
        :after_remove => Proc.new {|user, group_user| group_user.group.user_removed(user)}

      has_many :groups, :through => :groups_users,
        :after_add => Proc.new {|user, group| group.user_added(user)},
        :after_remove => Proc.new {|user, group| group.user_removed(user)}


      has_many :rates, :class_name => 'HourlyRate'
      has_many :default_rates, :class_name => 'DefaultHourlyRate'

      before_save :save_rates

      alias_method_chain :allowed_to?, :inheritance
    end

  end

  module InstanceMethods
    def allowed_for_role(action, project, role, users, options={})
      allowed = role.allowed_to?(action)

      if action.is_a? Symbol
        perm = Redmine::AccessControl.permission(action)
        if perm.granular_for
          allowed && users.include?(options[:for] || self)
        elsif !allowed && options[:for] && granulars = Redmine::AccessControl.permissions.select{|p| p.granular_for == perm}
          granulars.detect{|p| self.allowed_to? p.name, project, options}
        else
          allowed
        end
      else
        allowed
      end
    end

    def granular_roles_for_project(project)
      roles = {}
      # No role on archived projects
      return roles unless project && project.active?
      if logged?
        # Find project membership
        membership = memberships.detect {|m| m.project_id == project.id}
        if membership
          roles = granular_roles(membership.member_roles)
        else
          @role_non_member ||= Role.non_member
          roles[@role_non_member] = [self]
        end
      else
        @role_anonymous ||= Role.anonymous
        roles[@role_anonymous] = [self]
      end
      roles
    end

    # Return true if the user is allowed to do the specified action on project
    # action can be:
    # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
    # * a permission Symbol (eg. :edit_project)
    def allowed_to_with_inheritance?(action, context, options={})
      allowed_for_role = Proc.new do |role, users|
        self.allowed_for_role(action, context, role, users, options)
      end

      options[:for] = self unless options.has_key?(:for)

      if context && context.is_a?(Project)
        # No action allowed on archived projects
        return false unless context.active?
        # No action allowed on disabled modules
        return false unless context.allows_to?(action)
        # Admin users are authorized for anything else
        return true if admin?
        
        roles = granular_roles_for_project(context)
        return false unless roles
        allowing_role_pair = roles.detect do |role, users|
          if (context.is_public? || role.member?)
            allowed_for_role.call(role, users)
          else
            false
          end
        end
        allowing_role_pair ? allowing_role_pair[0] : allowing_role_pair #the role
      elsif context && context.is_a?(Array)
        # Authorize if user is authorized on every element of the array
        context.map do |project|
          allowed_to?(action, project, options)
        end.inject do |memo,allowed|
          memo && allowed
        end

      elsif options[:global]
        # Admin users are always authorized
        return true if admin?

        # authorize if user has at least one role that has this permission
        roles = memberships.inject({}) do |roles, m|
          granular_roles(m.member_roles).each_pair do |role, users|
            if roles[role]
              roles[role] |= users unless users.nil?
            else
              roles[role] = users
            end
            
            roles
          end
          roles
        end

        allowing_role = roles.detect(&allowed_for_role)
        if allowing_role
          allowing_role[0]
        else
          self.logged? ? allowed_for_role.call(Role.non_member, [self]) : allowed_for_role.call(Role.anonymous, [self])
        end

      else
        false
      end
    end

    def allowed_for(permission, projects = nil)
      unless projects.nil? or projects.blank?
        projects = [projects] unless projects.is_a? Array
        projects, ids = projects.partition{|p| p.is_a?(Project)}
        projects += Project.find_all_by_id(ids)
      else
        vis_projects = Project.find(:all, :conditions => Project.visible_by(self), :include => [:enabled_modules])
        projects = vis_projects + (projects.nil? ? [] : projects)
        # In case there is no Project, we assume that an admin still has all the permissions
        return (self.admin? ? "(1=1)" : "(1=0)") if projects.blank?
      end

      return "(#{Project.table_name}.id in (#{projects.collect(&:id).join(", ")}))" if self.admin?

      user_list = projects.inject({}) do |user_list, project|
        roles = granular_roles_for_project(project)
        return user_list unless roles

        users_for_project = []
        roles.each_pair do |role, users|
          if (project.is_public? || role.member?)
            if !Redmine::AccessControl.permission(permission).granular_for && self.allowed_for_role(permission, project, role, users)
              users_for_project = nil
              break
            elsif self.allowed_for_role(permission, project, role, users, :for => self)
              users_for_project += users.collect(&:id)
            end
          end
        end
        if users_for_project.nil? || !users_for_project.empty?
          users_for_project.sort!.uniq! unless users_for_project.nil?
          user_list[users_for_project] ||= []
          user_list[users_for_project] << project.id
        end
        user_list
      end

      cond = ["0=1"]
      user_list.each_pair do |users, projects|
        if users
          cond << "(#{Project.table_name}.id in (#{projects.join(", ")}) AND #{User.table_name}.id IN (#{users.join(", ")}))"
        else
          cond << "(#{Project.table_name}.id in (#{projects.join(", ")}))"
        end
      end
      "(#{cond.join " OR "})"
    end

    def current_rate(project = nil, include_default = true)
      rate_at(Date.today, project, include_default)
    end

    def rate_at(date, project = nil, include_default = true)
      unless project.nil?
        rate = HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id = ? and valid_from <= ?", id, project, date], :order => "valid_from DESC")
        if rate.nil?
          project = Project.find(project) unless project.is_a?(Project)
          rate = HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id in (?) and valid_from <= ?", id, project.ancestors, date], :include => :project, :order => "projects.lft DESC, valid_from DESC")
        end
      end
      rate ||= default_rate_at(date) if include_default
      rate
    end

    def current_default_rate()
      default_rate_at(Date.today)
    end

    def default_rate_at(date)
      DefaultHourlyRate.find(:first, :conditions => [ "user_id = ? and valid_from <= ?", id, date], :order => "valid_from DESC")
    end

    def add_rates(project, rate_attributes)
      # set project to nil to set the default rates

      return unless rate_attributes

      rate_attributes.each do |index, attributes|
        attributes[:rate] = Rate.clean_currency(attributes[:rate])

        if project.nil?
          default_rates.build(attributes)
        else
          attributes[:project] = project
          rates.build(attributes)
        end
      end
    end

    def set_existing_rates (project, rate_attributes)
      if project.nil?
        default_rates.reject(&:new_record?).each do |rate|
          update_rate(rate, rate_attributes, false)
        end
      else
        rates.reject{|r| r.new_record? || r.project_id != project.id}.each do |rate|
          update_rate(rate, rate_attributes, true)
        end
      end
    end

    def save_rates
      (default_rates + rates).each do |rate|
        rate.save(false)
      end
    end


  private
    def granular_roles(member_roles)
      roles = {}
      member_roles.each do |r|
        roles[r.role] = [self]

        if r.inherited_from
          # the role was inherited from a group
          case r.membership_type
          when :controller
            inherited = MemberRole.find_by_id(r.inherited_from)
            users = [self]
            users += inherited.member.users# if inherited.member.principal.is_a? Group

            roles[r.role] = users
          else # :default
            #nothing
          end
        end
      end
      roles
    end

    def update_rate(rate, rate_attributes, project_rate = true)
      attributes = rate_attributes[rate.id.to_s] if rate_attributes

      has_rate = false
      if attributes && attributes[:rate].present?
        attributes[:rate] = Rate.clean_currency(attributes[:rate])
        has_rate = true
      end

      if has_rate
        rate.attributes = attributes
      else
        project_rate ? rates.delete(rate) : default_rates.delete(rate)
      end
    end
  end
end

User.send(:include, CostsUserPatch)
