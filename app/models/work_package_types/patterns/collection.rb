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

module WorkPackageTypes
  module Patterns
    Collection = Data.define(:patterns) do
      extend Dry::Monads[:result]

      private_class_method :new

      def self.empty
        new(patterns: {})
      end

      def self.build(patterns:, contract: CollectionContract.new)
        contract.call(patterns).to_monad.fmap { |success| new(success.to_h) }
      rescue ArgumentError => e
        Failure(e)
      end

      def initialize(patterns:)
        transformed = patterns.transform_values { Pattern.new(**it) }.freeze

        super(patterns: transformed)
      end

      def subject
        patterns[:subject]
      end

      def all_enabled
        patterns.select { |_, pattern| pattern.enabled? }
      end

      def to_h
        patterns.stringify_keys.transform_values(&:to_h)
      end
    end
  end
end
