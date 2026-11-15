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

module Queries::Filters::Shared::ProjectIds
  # Project identifiers are never all-numeric (see Projects::Identifier).
  PROJECT_ID_FORMAT = /\A-?\d+\z/

  def values=(values)
    super
    @ids_by_value = nil
  end

  def project_ids
    project_values.map { project_id_for(it) }
  end

  def project_id_for(value)
    ids_by_value.fetch(value, value)
  end

  private

  def project_values = values

  def visible_projects = Project.visible

  def ids_by_value
    @ids_by_value ||= begin
      identifiers = project_values.reject { it.blank? || it.match?(PROJECT_ID_FORMAT) }
      identifiers.empty? ? {} : visible_projects.ids_by_identifier(identifiers).transform_values(&:to_s)
    end
  end
end
