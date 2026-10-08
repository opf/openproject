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

    def self.for(user, work_packages)
      ids = work_packages.flat_map { it.subject.scan(PATTERN) }.flatten

      WorkPackage
        .visible(user)
        .where_display_id_in(ids)
        .includes(:status, :project, :type)
        .flat_map { [[it.id.to_s, it], [it.display_id.to_s, it]] }
        .to_h
    end
  end
end
