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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module NamedReferences
    # The creation wizard carries the form or workflow it started for a variant in its URLs, so
    # that it can tell that record apart from the ones the variant reuses, and discard it once abandoned.
    class DiscardStartedService
      def self.param_key(model_class) = :"started_#{model_class.variant_reflection.foreign_key}"
      private_class_method :param_key

      def self.params_for(model_class, id) = { param_key(model_class) => id }.compact

      def self.id_in(params, model_class) = Integer(params[param_key(model_class)].to_s, 10, exception: false)

      def self.carry_in(url, record)
        uri = URI.parse(url)
        uri.query = Rack::Utils.parse_nested_query(uri.query.to_s).merge(param_key(record.class).to_s => record.id).to_query
        uri.to_s
      end

      def initialize(model_class:)
        @model_class = model_class
      end

      # Destroying is refused while any variant still uses the record.
      def call(id)
        record = id && model_class.find_by(id:)
        return ServiceResult.success if record.nil?

        if record.destroy
          ServiceResult.success(result: record)
        else
          ServiceResult.failure(result: record, errors: record.errors)
        end
      end

      private

      attr_reader :model_class
    end
  end
end
