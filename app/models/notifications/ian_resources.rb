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

# Registry of resource types that are allowed to surface as in-app
# notifications (IAN) in the notification center. Historically only
# WorkPackage was supported; resources register themselves here so the
# visible scope and the query filters stay type-agnostic.
module Notifications
  module IanResources
    Registration = Data.define(:resource_type, :visible)

    class << self
      # @param model_class The resource ActiveRecord class.
      # @param visible A callable returning the relation of records of that
      #   class visible to the given user.
      def register(model_class, visible: ->(user) { model_class.visible(user) })
        registrations[model_class.name] = Registration.new(model_class.name, visible)
      end

      def all
        registrations.values
      end

      def resource_types
        registrations.keys
      end

      private

      def registrations
        @registrations ||= {}
      end
    end
  end
end
