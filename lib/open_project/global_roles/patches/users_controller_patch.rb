#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_dependency "users_controller"

module OpenProject::GlobalRoles::Patches
  module UsersControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :add_global_roles, :only => [:edit]
      end
    end

    module InstanceMethods
      private
      def add_global_roles
        @global_roles = GlobalRole.all
      end
    end
  end
end

UsersController.send(:include, OpenProject::GlobalRoles::Patches::UsersControllerPatch)
