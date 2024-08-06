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

class Queries::Capabilities::CapabilityQuery
  include Queries::BaseQuery
  include Queries::UnpersistedQuery

  def self.model
    Capability
  end

  def results
    super
      .reorder("action ASC", "principal_id ASC", "capabilities.context_id ASC")
  end

  def default_scope
    Capability
      .default
      .distinct
  end

  validate :minimum_filters_set

  private

  def minimum_filters_set
    any_required = filters.any? do |filter|
      [Queries::Capabilities::Filters::PrincipalIdFilter,
       Queries::Capabilities::Filters::ContextFilter,
       Queries::Capabilities::Filters::IdFilter].include?(filter.class) && filter.operator == "="
    end

    errors.add(:filters, I18n.t("activerecord.errors.models.capability.query.filters.minimum")) unless any_required
  end
end
