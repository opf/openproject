#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Provides aliases to hierarchy_*
# methods to stay compatible with code written for awesome_nested_set

module WorkPackage::TypedDagDefaults
  extend ActiveSupport::Concern

  included do
    # Can't use .alias here
    # as the dag methods are mixed in later

    def leaves
      hierarchy_leaves
    end

    def self.leaves
      hierarchy_leaves
    end

    def leaf?
      # The leaf? implementation relies on the children relations. If that relation is not loaded,
      # rails will attempt to do the performant check on whether such a relation exists at all. While
      # This is performant for one call, subsequent calls have to again fetch from the db (cached admittedly)
      # as the relations are still not loaded.
      # For reasons I could not find out, adding a #reload method here lead to the virtual attribute management for parent
      # to no longer work. Resetting the @is_leaf method was hence moved to the WorkPackage::Parent module
      @is_leaf ||= hierarchy_leaf?
    end

    def root
      hierarchy_roots.first
    end

    def self.roots
      hierarchy_roots
    end

    def root?
      hierarchy_root?
    end

    private

    def reset_is_leaf
      @is_leaf = nil
    end
  end
end
