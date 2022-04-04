#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module API
  class ParserStruct < ::Hashie::Mash
    ##
    # TODO: Hashie::Mash extends from Hash and
    # does not allow overriding any enumerable methods.
    #
    # This clashed with moving the queries services to BaseContracted,
    # as we now use a +group_by+ attribute clashing with +Enumerable#group_by#.
    # This redefines the method to ensure it works with queries, but does not solve the underlying issue.
    def group_by
      self[:group_by]
    end
  end
end
