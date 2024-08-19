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

module Queries::Filters::Shared::ProjectFilter::Required
  def self.included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def allowed_values
      # We don't care for the first value as we do not display the values visibly
      @allowed_values ||= ::Project.visible.pluck(:id).map { |id| [id, id.to_s] }
    end

    def type
      :list
    end

    def type_strategy
      # Instead of getting the IDs of all the projects a user is allowed
      # to see we only check that the value is an integer.  Non valid ids
      # will then simply create an empty result but will not cause any
      # harm.
      @type_strategy ||= ::Queries::Filters::Strategies::IntegerList.new(self)
    end
  end

  module ClassMethods
    def key
      :project_id
    end
  end
end
