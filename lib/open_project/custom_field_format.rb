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

module OpenProject
  class CustomFieldFormat
    include Redmine::I18n

    class_attribute :registered_by_name, default: {}

    attr_reader :name, :order, :label, :edit_as

    def initialize(name,
                   label:,
                   order:,
                   edit_as: name,
                   only: nil,
                   multi_value_possible: false,
                   enterprise_feature: nil,
                   enabled: lambda { true },
                   formatter: "CustomValue::StringStrategy")
      @name = name
      @label = label
      @order = order
      @edit_as = edit_as
      @class_names = only
      @multi_value_possible = multi_value_possible
      @enterprise_feature = enterprise_feature
      @enabled = enabled
      @formatter = formatter
    end

    def multi_value_possible?
      @multi_value_possible
    end

    def formatter
      # avoid using stale definitions in dev mode
      Kernel.const_get(@formatter)
    end

    def available?
      enabled? && enterprise_feature_allowed?
    end

    def enabled?
      @enabled.call
    end

    def disabled?
      !enabled?
    end

    def enterprise_feature_allowed?
      !@enterprise_feature || EnterpriseToken.allows_to?(@enterprise_feature)
    end

    def for_class_name?(class_name)
      (@class_names.nil? || @class_names.include?(class_name)) && !label.nil?
    end

    class << self
      def register(name, **)
        return if registered_by_name.has_key?(name)

        registered_by_name[name] = new(name, **)
        @registered = nil
      end

      def find_by(name:)
        registered_by_name[name.to_s]
      end

      def registered
        @registered ||= registered_by_name.values.sort_by(&:order)
      end

      def available = registered.select(&:available?)
      def enabled = registered.select(&:enabled?)
      def disabled = registered.select(&:disabled?)

      def registered_formats = registered.map(&:name)
      def available_formats = available.map(&:name)
      def enabled_formats = enabled.map(&:name)
      def disabled_formats = disabled.map(&:name)

      def enabled_for_class_name(class_name)
        filter_for_class_name(enabled, class_name)
      end

      def available_for_class_name(class_name)
        filter_for_class_name(available, class_name)
      end

      private

      def filter_for_class_name(list, class_name)
        list.select { |format| format.for_class_name?(class_name) }
      end
    end
  end
end
