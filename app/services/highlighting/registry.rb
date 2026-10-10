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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Highlighting
  class Registry
    class << self
      # Returns a hash of registered resources. The color values are stored as callback functions.
      def entries
        @entries ||= {}
      end

      def cache_key
        OpenProject::Cache::CacheKey.expand [last_updated_at, *static_data]
      end

      # Register an active record model to being used for highlighting color calculation.
      # Only models with a reference to `Color` or the `Color` model itself are allowed.
      def register_model(key:, model:)
        if entries.has_key?(key)
          warn "Key already exists. Registration attempt rejected for key '#{key}'."
          return
        end

        if models.include?(model)
          warn "Model already registered. Registration attempt rejected for model '#{model}'."
          return
        end

        models << model

        # `Color` is the only model that can get registered as is. For other models we require
        # a reference to the color entity.
        lambda = model == ::Color ? -> { model.all } : -> { model.includes(:color) }
        entries[key.to_s] = lambda
      end

      # Register static data for highlighting color calculation. The values must be an array of objects
      # responding to `id` and returning a `Color` on `color`.
      def register_static(key:, values:)
        if entries.has_key?(key)
          Rails.logger.warning "Key already exists. Registration attempt rejected for key '#{key}'."
          return
        end

        if values.all? { |value| value.respond_to?(:color) && value.respond_to?(:id) }
          static_data << values
          entries[key.to_s] = -> { values }
        else
          Rails.logger.warning(
            "Values registered for key '#{key}' do not respond to necessary properties. Registration attempt rejected."
          )
        end
      end

      private

      def models
        @models ||= []
      end

      def static_data
        @static_data ||= []
      end

      def last_updated_at
        ApplicationRecord.most_recently_changed(*models)
      end

      def warn(message)
        Rails.logger.warning message
      end
    end
  end
end
