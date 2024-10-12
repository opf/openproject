#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

class CustomActions::Actions::DoneRatio < CustomActions::Actions::Base
  include CustomActions::Actions::Strategies::Integer

  def self.key
    :done_ratio
  end

  def apply(work_package)
    if WorkPackage.use_field_for_done_ratio?
      WorkPackages::SetAttributesService.new(user: User.current,
                                             model: work_package,
                                             contract_class: WorkPackages::UpdateContract)
                                        .call(remaining_hours: compute_remaining_hours(work_package))
    end
  end

  def minimum
    0
  end

  def maximum
    100
  end

  def self.all
    if WorkPackage.work_based_mode?
      super
    else
      []
    end
  end

  private

  def compute_remaining_hours(work_package)
    work_done = (work_package.estimated_hours * (values.first / 100.to_f))
    work_package.estimated_hours - work_done
  end
end
