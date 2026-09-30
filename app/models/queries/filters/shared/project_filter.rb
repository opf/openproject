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

module Queries::Filters::Shared::ProjectFilter
  PROJECT_ID_FORMAT = /\A-?\d+\z/

  # A project identifier is never all-numeric (see Projects::Identifier), so an
  # integer value can only ever mean a primary key.
  def self.replace_identifiers_with_ids(values)
    values = Array(values).map(&:to_s)
    identifiers = values.reject { |value| value.blank? || value.match?(PROJECT_ID_FORMAT) }
    return values if identifiers.empty?

    ids = ids_by_identifier(identifiers)

    values.map { |value| ids.fetch(value.downcase, value) }
  end

  def self.ids_by_identifier(identifiers)
    Project
      .visible
      .by_identifiers_ci(identifiers)
      .pluck(:identifier, :id)
      .to_h { |identifier, id| [identifier.downcase, id.to_s] }
  end
  private_class_method :ids_by_identifier
end
