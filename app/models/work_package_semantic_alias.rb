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

# Maps a semantic identifier (e.g. "PROJ-42") to a work package.
# This acts as a registry of all semantic identifiers for a work package,
# including both the current identifier and any retired ones created by moves
# or project renames. The current identifier is also stored directly on
# work_packages.identifier for faster access.
#
# The write side of the registry lives in WorkPackage::SemanticIdentifier:
#   wp.allocate_and_register_semantic_id                  # on WP project change (call post-save)
#   project.handle_semantic_rename(old_identifier)      # on project identifier change
class WorkPackageSemanticAlias < ApplicationRecord
  belongs_to :work_package, inverse_of: :semantic_aliases

  validates :identifier, presence: true, uniqueness: true
  validates :work_package, presence: true

  # Aliases created for the given project slug prefix, i.e. identifiers of the
  # exact form "<slug>-<digits>". Case-sensitive: aliases are always created
  # verbatim from slug values, and slugs differing only in case (classic "proj"
  # vs semantic "PROJ") are distinct reservations.
  scope :for_slug_prefix, ->(slug) {
    where("identifier ~ ?", WorkPackage::SemanticIdentifier.slug_prefix_pattern(slug))
  }
end
