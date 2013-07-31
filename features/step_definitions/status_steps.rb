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

Given /^there is a(?:n)? (default )?(?:issue)?status with:$/ do |default, table|
  name = table.raw.select { |ary| ary.include? "name" }.first[table.raw.first.index("name") + 1].to_s
  IssueStatus.find_by_name(name) || IssueStatus.create(:name => name.to_s, :is_default => !!default)
end

Given /^there are the following status:$/ do |table|
  table.hashes.each do |row|
    attributes = row.inject({}) { |mem, (k, v)| mem[k.to_sym] = v if v.present?; mem }
    attributes[:is_default] = attributes.delete(:default) == "true"

    FactoryGirl.create(:issue_status, attributes)
  end
end

