#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

Then(/^the available status of the story called "(.+?)" should be the following:$/) do |story_name, table|
  # the order of the available status is important
  story = Story.find_by(subject: story_name)

  within("#story_#{story.id} .editors") do
    table.raw.flatten.each do |option_text|
      should have_select('status_id', text: option_text)
    end
  end
end

Then(/^the displayed attributes of the story called "(.+?)" should be the following:$/) do |story_name, table|
  story = Story.find_by(subject: story_name)

  within("#story_#{story.id}") do
    table.rows_hash.each do |key, value|
      case key
      when 'Status'
        within('.status_id') do
          should have_selector('div.t', text: value)
        end
      else
        raise 'Not an implemented attribute'
      end
    end
  end
end

Then(/^the editable attributes of the story called "(.+?)" should be the following:$/) do |story_name, table|
  story = Story.find_by(subject: story_name)

  within("#story_#{story.id} .editors") do
    table.rows_hash.each do |key, value|
      case key
      when 'Status'
        should have_select('status_id', text: value)
      else
        raise 'Not an implemented attribute'
      end
    end
  end
end
