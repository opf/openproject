#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Backlogs::Patches::UpdateAncestorsServicePatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    private

    ##
    # Overrides method in original UpdateAncestorsService.
    def inherit_attributes(ancestor, loader, attributes)
      super

      derive_remaining_hours(ancestor, loader) if inherit?(attributes, :remaining_hours)
    end

    def derive_remaining_hours(work_package, loader)
      descendants = loader.descendants_of(work_package)

      work_package.derived_remaining_hours = not_zero(all_remaining_hours(descendants).sum.to_f)
    end

    def all_remaining_hours(work_packages)
      work_packages.map(&:remaining_hours).reject { |hours| hours.to_f.zero? }
    end

    def attributes_justify_inheritance?(attributes)
      super || attributes.include?(:remaining_hours)
    end
  end
end
