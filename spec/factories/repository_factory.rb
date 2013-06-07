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

FactoryGirl.define do
  factory :repository, :class => Repository::Filesystem do
    # Setting.enabled_scm should include "Filesystem" to successfully save the created repository
    url 'file:///tmp/test_repo'
    project
  end
end
