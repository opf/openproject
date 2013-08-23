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

module OpenProject::GlobalRoles::Patches
  module PrincipalPatch
    def self.included(base)
      base.class_eval do

        has_many :principal_roles, :dependent => :destroy
        has_many :global_roles, :through => :principal_roles, :source => :role
      end
    end
  end
end

Principal.send(:include, OpenProject::GlobalRoles::Patches::PrincipalPatch)
