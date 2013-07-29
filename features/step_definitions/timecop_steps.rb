#encoding: utf-8

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

Given /^the time is ([0-9]+) minutes later$/ do |duration|
  Timecop.travel(Time.now + duration.to_i.minutes)
end

Given /^the time is ([0-9]+) days later$/ do |duration|
  Timecop.travel(Time.now + duration.to_i.days)
end

# Ensure timecop returns after each scenario
After do
  Timecop.return
end
