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

module Queries
  module Filters
    module Serializable
      include ActiveModel::Serialization
      extend ActiveSupport::Concern

      class_methods do
        # (de-)serialization
        def from_hash(filter_hash)
          filter_hash.keys.map do |field|
            begin
              create!(name, filter_hash[field])
            rescue ::Queries::Filters::InvalidError
              Rails.logger.error "Failed to constantize field filter #{field} from hash."
              ::Queries::NotExistingFilter.create!(field)
            end
          end
        end
      end

      def to_hash
        { name => attributes_hash }
      end

      def attributes
        { name: name, operator: operator, values: values }
      end

      def ==(other)
        other.try(:attributes_hash) == attributes_hash
      end

      protected

      def attributes_hash
        self.class.filter_params.inject({}) do |params, param_field|
          params.merge(param_field => send(param_field))
        end
      end

      private

      def stringify_values
        unless values.nil?
          values.map!(&:to_s)
        end
      end
    end
  end
end
