#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_dependency "roles_helper"

module OpenProject::GlobalRoles::Patches
  module RolesHelperPatch
    def self.included(base)
      base.class_eval do

        def permissions_id permissions
          "permissions_" + permissions[0].hash.to_s
        end
      end
    end
  end
end

RolesHelper.send(:include, OpenProject::GlobalRoles::Patches::RolesHelperPatch)
