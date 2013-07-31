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

Then /I should see a journal with the following:$/ do |table|
  if table.rows_hash["Notes"]
    should have_css(".journal", :text => table.rows_hash["Notes"])
  end
end
