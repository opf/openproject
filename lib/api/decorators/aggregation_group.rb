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

module API
  module Decorators
    class AggregationGroup < Single
      def initialize(group_key, count, sums: nil)
        @count = count
        @sums = sums

        @link = ::API::V3::Utilities::ResourceLinkGenerator.make_link(group_key)

        super(group_key)
      end

      link :valueLink do
        {
          href: @link
        } if @link
      end

      property :value,
               exec_context: :decorator,
               getter: -> (*) { represented ? represented.to_s : nil },
               render_nil: true

      property :count,
               exec_context: :decorator,
               getter: -> (*) { @count },
               render_nil: true

      property :sums,
               exec_context: :decorator,
               getter: -> (*) { @sums },
               render_nil: false
    end
  end
end
