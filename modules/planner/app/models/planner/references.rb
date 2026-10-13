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

module Planner
  # Work packages the user can see that task subjects reference, keyed by every id they may be
  # written with.
  class References
    PATTERN = /(?<![\w#])\#{1,3}(#{WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN.source}|\d+)\b/
    ONLY = /\A\s*#{PATTERN.source}\s*\z/

    def self.for(user, work_packages)
      WorkPackage
        .visible(user)
        .where_display_id_in(work_packages.flat_map { ids_in(it.subject) })
        .includes(:status, :project, :type)
        .flat_map { |work_package| ids_of(work_package).map { [it, work_package] } }
        .to_h
    end

    def self.ids_in(text) = text.to_s.scan(PATTERN).flatten

    def self.ids_of(work_package) = [work_package.id.to_s, work_package.display_id.to_s]

    # A task whose subject is nothing but a reference stands for the referenced work package.
    def self.planned_id(subject) = subject[ONLY, 1]
  end
end
