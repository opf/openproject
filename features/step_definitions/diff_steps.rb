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

# Please note that this is zero based
When(/^I follow the link to see the diff in the (.+?) journal$/) do |nth|
  within all(".journal .details")[nth.to_i] do
    click_link I18n.t(:label_details)
  end
end

When(/^I should see the following inline diff(?: on (.+?)):$/) do |page, table|
  if page
    step %Q{I should be on #{page}}
  end

  table.rows_hash.each do |key, value|
    case key
    when "new"
      find "ins.diffmod", :text => value
    when "old"
      find "del.diffmod", :text => value
    when "unchanged"
      find ".text-diff", :text => value
    else
      raise ArgumentError, "#{ key } is not supported. 'new', 'old', 'unchanged' is."
    end
  end
end

