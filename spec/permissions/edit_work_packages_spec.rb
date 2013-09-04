#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../support/permission_specs', __FILE__)

describe WorkPackagesController, "edit_work_packages permission", :type => :controller do
  include PermissionSpecs

  check_permission_required_for('work_packages#edit', :edit_work_packages)
  check_permission_required_for('work_packages#update', :edit_work_packages)
  check_permission_required_for('work_packages#new_type', :edit_work_packages)
  check_permission_required_for('work_packages#quoted', :edit_work_packages)
end
