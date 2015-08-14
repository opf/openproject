#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json'
require 'roar/json/collection'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      class WorkPackageCollectionRepresenter < ::API::Decorators::OffsetPaginatedCollection
        element_decorator ::API::V3::WorkPackages::WorkPackageRepresenter

        def initialize(models,
                       self_link,
                       query: {},
                       total_sums:,
                       page: nil,
                       per_page: nil,
                       context: {})
          @total_sums = total_sums

          super(models, self_link, query: query, page: page, per_page: per_page, context: context)
        end

        property :total_sums,
                 exec_context: :decorator,
                 getter: -> (*) {
                   @total_sums
                 },
                 render_nil: false
      end
    end
  end
end
