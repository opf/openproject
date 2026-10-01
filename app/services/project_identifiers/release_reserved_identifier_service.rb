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

module ProjectIdentifiers
  # Releases a historically reserved project identifier slug.
  # Additionally removes the WorkPackageSemanticAlias rows created for that
  # slug prefix ("<slug>-<digits>") atomically with the slug destroy, so the
  # released prefix no longer resolves work packages. In classic mode it also
  # clears stale work package identifier columns carrying the prefix
  # (leftovers from a previous semantic phase), which would otherwise keep old
  # links resolving and shadow the alias rows of a new project claiming the
  # identifier after a later re-conversion.
  class ReleaseReservedIdentifierService
    def initialize(slug)
      @slug = slug
    end

    def call
      FriendlyId::Slug.transaction do
        delete_aliases
        clear_stale_work_package_identifiers
        @slug.destroy!
      end

      ServiceResult.success
    end

    private

    def delete_aliases
      WorkPackageSemanticAlias.for_slug_prefix(@slug.slug).delete_all
    end

    # A historically reserved slug is no project's current identifier, so any
    # work package still carrying "<slug>-<digits>" in its identifier column is
    # stale (left over from a revert to classic mode). The finder resolves
    # semantic identifiers against this column as well as the alias table, so
    # clearing it severs resolution immediately instead of waiting for the next
    # semantic conversion's reset_stale_identifiers to do the same.
    #
    # Only relevant in classic mode: in semantic mode the identifier column
    # carries the live semantic identifiers of the projects currently using
    # the mode, which must not be cleared.
    def clear_stale_work_package_identifiers
      return unless Setting::WorkPackageIdentifier.classic?

      WorkPackage.for_slug_prefix(@slug.slug).update_all(identifier: nil, sequence_number: nil)
    end
  end
end
