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

if IssuePriority.any?
  puts '***** Skipping priorities as there are already some configured'
else
  IssuePriority.transaction do
    IssuePriority.new.tap do |priority|
      priority.name = I18n.t(:default_priority_low)
      priority.position = 1
    end.save!

    IssuePriority.new.tap do |priority|
      priority.name = I18n.t(:default_priority_normal)
      priority.position = 2
      priority.is_default = true
    end.save!

    IssuePriority.new.tap do |priority|
      priority.name = I18n.t(:default_priority_high)
      priority.position = 3
    end.save!

    IssuePriority.new.tap do |priority|
      priority.name = I18n.t(:default_priority_immediate)
      priority.position = 4
    end.save!
  end
end
