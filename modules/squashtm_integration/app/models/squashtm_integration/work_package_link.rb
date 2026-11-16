# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module SquashTMIntegration
  class WorkPackageLink < ApplicationRecord
    self.table_name = "squashtm_work_package_links"

    belongs_to :work_package

    delegate :project, to: :work_package, allow_nil: true

    validates :work_package, presence: true
    validate :single_link_per_work_package

    # After a failed update the in-memory values carry the rejected requirement, so a persisted link reports the stored ones.
    def stored_squashtm_requirement_id
      persisted? ? squashtm_requirement_id_in_database : squashtm_requirement_id
    end

    def stored_squashtm_requirement_name
      persisted? ? squashtm_requirement_name_in_database : squashtm_requirement_name
    end

    private

    def single_link_per_work_package
      errors.add(:base, :work_package_already_linked) if self.class.where.not(id:).exists?(work_package_id:)
    end
  end
end
