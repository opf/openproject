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

if TimeEntryActivity.any?
  puts '***** Skipping activities as there are already some configured'
else
  TimeEntryActivity.transaction do
    TimeEntryActivity.new.tap do |activity|
      activity.name = I18n.t(:default_activity_management)
      activity.position = 1
      activity.is_default = true
    end.save!

    TimeEntryActivity.new.tap do |activity|
      activity.name = I18n.t(:default_activity_specification)
      activity.position = 2
    end.save!

    TimeEntryActivity.new.tap do |activity|
      activity.name = I18n.t(:default_activity_development)
      activity.position = 3
    end.save!

    TimeEntryActivity.new.tap do |activity|
      activity.name = I18n.t(:default_activity_testing)
      activity.position = 4
    end.save!

    TimeEntryActivity.new.tap do |activity|
      activity.name = I18n.t(:default_activity_support)
      activity.position = 5
    end.save!

    TimeEntryActivity.new.tap do |activity|
      activity.name = I18n.t(:default_activity_other)
      activity.position = 6
    end.save!
  end
end
