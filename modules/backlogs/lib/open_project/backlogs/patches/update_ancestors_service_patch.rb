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

module OpenProject::Backlogs::Patches::UpdateAncestorsServicePatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    private

    ##
    # Overrides method in original UpdateAncestorsService.
    def inherit_attributes(ancestor, attributes)
      super

      inherit_remaining_hours(ancestor) if inherit?(attributes, :remaining_hours)
    end

    def inherit_remaining_hours(ancestor)
      ancestor.remaining_hours = all_remaining_hours(leaves_for_work_package(ancestor)).sum.to_f
      ancestor.remaining_hours = nil if ancestor.remaining_hours == 0.0
    end

    def all_remaining_hours(work_packages)
      work_packages.map(&:remaining_hours).reject { |hours| hours.to_f.zero? }
    end

    def attributes_justify_inheritance?(attributes)
      super || attributes.include?(:remaining_hours)
    end

    def selected_leaves_attributes
      super + [:remaining_hours]
    end
  end
end
