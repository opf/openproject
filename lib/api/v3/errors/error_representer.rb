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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module Errors
      class ErrorRepresenter < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::Hypermedia

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        property :_type, exec_context: :decorator
        property :error_identifier, exec_context: :decorator, render_nil: true
        property :message, getter: ->(*) { message }, render_nil: true
        property :details, embedded: true

        collection :errors,
                   embedded: true,
                   class: ::API::Errors::ErrorBase,
                   decorator: ::API::V3::Errors::ErrorRepresenter,
                   if: ->(*) { !Array(errors).empty? }

        def _type
          "Error"
        end

        def error_identifier
          ::API::V3::URN_ERROR_PREFIX + represented.class.identifier
        end
      end
    end
  end
end
