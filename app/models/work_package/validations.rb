#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module WorkPackage::Validations
  extend ActiveSupport::Concern

  included do
    validates :subject, :priority, :project, :type, :author, :status, presence: true

    validates :subject, length: { maximum: 255 }
    validates :done_ratio, inclusion: { in: 0..100 }
    validates :estimated_hours, numericality: { allow_nil: true }
    validates :remaining_hours, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }
    validates :derived_remaining_hours, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }

    validates :due_date, date: { allow_blank: true }
    validates :start_date, date: { allow_blank: true }

    scope :eager_load_for_validation, -> {
      includes({ project: %i(enabled_modules work_package_custom_fields versions) },
               { parent: :type },
               :custom_values,
               { type: :custom_fields },
               :priority,
               :status,
               :author,
               :category,
               :version)
    }
  end
end
