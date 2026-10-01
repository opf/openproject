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

class Queries::ProjectReservedIdentifiers::ProjectReservedIdentifierQuery
  include Queries::BaseQuery
  include Queries::UnpersistedQuery

  def self.model
    FriendlyId::Slug
  end

  def default_scope
    # Pure-numeric slugs are legacy artifacts (identifier validation was tightened
    # later; the semantic-conversion autofix renames such projects, reserving the
    # old numeric identifier). Releasing them frees nothing — numeric identifiers
    # are invalid in both formats — and would break friendly_id history resolution
    # of old /projects/<number> links, letting them fall through to a primary-key
    # lookup of a different project.
    Project.identifier_slugs
      .historically_reserved
      .where("slug !~ ?", "^[0-9]+$")
      .joins("JOIN projects ON projects.id = friendly_id_slugs.sluggable_id")
      .order("projects.name ASC, friendly_id_slugs.created_at DESC")
  end
end
