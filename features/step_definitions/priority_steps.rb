# encoding: utf-8

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

InstanceFinder.register(IssuePriority, Proc.new{ |name| IssuePriority.find_by_name(name) })

Given /^there is a(?:n)? (default )?issuepriority with:$/ do |default, table|
  name = table.raw.select { |ary| ary.include? "name" }.first[table.raw.first.index("name") + 1].to_s
  project = get_project
  FactoryGirl.build(:priority).tap do |prio|
    prio.name = name
    prio.is_default = !!default
    prio.project = project
  end.save!
end
