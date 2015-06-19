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

module WorkPackage::SchedulingRules
  extend ActiveSupport::Concern

  included do
    # add class-methods (validations, scope) here
  end

  def reschedule_after(date)
    return if date.nil?
    if leaf?
      if start_date.nil? || start_date < date
        self.start_date, self.due_date = date, date + duration - 1
        save
      end
    else
      leaves.each do |leaf|
        # this depends on the "update_parent_attributes" after save hook
        # updating the start/end date of each work package between leaf and self
        leaf.reschedule_after(date)
      end
    end
  end

  # Returns the time scheduled for this work package.
  #
  # Example:
  #   Start Date: 2/26/09, Due Date: 3/04/09,  duration => 7
  #   Start Date: 2/26/09, Due Date: 2/26/09,  duration => 1
  #   Start Date: 2/26/09, Due Date: -      ,  duration => 1
  #   Start Date: -      , Due Date: 2/26/09,  duration => 1
  def duration
    if start_date && due_date
      due_date - start_date + 1
    else
      1
    end
  end
end
