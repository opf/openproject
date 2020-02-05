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

# This module includes some boilerplate code for pagination using scopes.
# #search_scope may be overridden by the model to change (restrict) the search scope
# and MUST return a scope or its corresponding hash.

module Pagination::Model
  def self.included(base)
    base.extend self
  end

  def self.extended(base)

    unless base.respond_to? :like
      base.scope :like, -> (q) {
        s = "%#{q.to_s.strip.downcase}%"
        base.where(['LOWER(name) LIKE :s', { s: s }])
          .order(Arel.sql('name'))
      }
    end

    base.instance_eval do
      def paginate_scope!(scope, options = {})
        limit = options.fetch(:page_limit) || 10
        page = options.fetch(:page) || 1

        scope.paginate(per_page: limit, page: page)
      end

      # ignores options passed in from the controller, overwrite to use 'em
      def search_scope(query, _options = {})
        like(query)
      end
    end
  end
end
