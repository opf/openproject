#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# Please note that this is zero based
When(/^I follow the link to see the diff in the (.+?) journal$/) do |nth|
  within all('.journal .details')[nth.to_i] do
    click_link I18n.t(:label_details)
  end
end

When(/^I should see the following inline diff(?: on (.+?)):$/) do |page, table|
  if page
    step %{I should be on #{page}}
  end

  table.rows_hash.each do |key, value|
    case key
    when 'new'
      find 'ins.diffmod', text: value
    when 'old'
      find 'del.diffmod', text: value
    when 'unchanged'
      find '.text-diff', text: value
    else
      raise ArgumentError, "#{ key } is not supported. 'new', 'old', 'unchanged' is."
    end
  end
end
