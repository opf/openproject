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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class ResourceAllocation < ApplicationRecord
  belongs_to :entity, polymorphic: true, optional: false
  belongs_to :principal, class_name: "User", optional: true, inverse_of: :resource_allocations

  serialize :user_filter, coder: Queries::Serialization::Filters.new(UserQuery)

  enum :state, {
    requested: "requested",
    allocated: "allocated",
    rejected: "rejected",
    canceled: "canceled"
  }

  validates :state, :start_date, :end_date, presence: true
  validates :allocated_time,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validate :end_date_after_start_date

  # Resource allocations are scoped to whatever project their (polymorphic)
  # entity belongs to. Authorization in the contracts hangs off this.
  def project
    entity&.project
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date > start_date

    errors.add :end_date, :greater_than_start_date
  end
end
