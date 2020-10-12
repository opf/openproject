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

module Grids::Configuration
  class Registration
    class_attribute :_widget_strategies,
                    :_defaults,
                    :_validations

    class << self
      private

      def macroed_getter_setter(name, type = :single)
        private_name = :"_#{name.to_s}"

        class_attribute private_name

        if type == Array
          define_singleton_method name do |*value|
            if value&.any?
              send(:"#{private_name}=", value)
            end

            send(private_name)
          end
        else
          define_singleton_method name do |value = nil|
            if value
              send(:"#{private_name}=", value)
            end

            send(private_name)
          end
        end
      end
    end

    macroed_getter_setter :widgets, Array
    macroed_getter_setter :grid_class
    macroed_getter_setter :to_scope

    class << self
      def widget_strategy(widget_name, &block)
        self._widget_strategies ||= {}

        if block_given?
          self._widget_strategies[widget_name.to_s] = Class.new(Grids::Configuration::WidgetStrategy, &block)
        end

        self._widget_strategies[widget_name.to_s] ||= Grids::Configuration::WidgetStrategy
      end

      def defaults(proc = nil)
        # This is called during code load, which
        # may not have the table available.
        return unless Grids::Widget.table_exists?

        if proc
          self._defaults = proc
        else
          params = _defaults.call
          params[:widgets] = (params[:widgets] || []).map do |widget|
            Grids::Widget.new(widget)
          end

          params
        end
      end

      def from_scope(_scope)
        raise NotImplementedError
      end

      def all_scopes
        Array(url_helpers.send(_to_scope))
      end

      def writable_scopes
        all_scopes
      end

      def visible(_user = User.current)
        ::Grids::Grid
          .where(type: grid_class)
      end

      def writable?(_grid, _user)
        true
      end

      def validations(mode = nil, proc = nil)
        self._validations ||= Hash.new do |hash, key|
          hash[key] = []
        end

        if mode && proc
          _validations[mode] << proc
        elsif mode
          _validations[mode] || []
        end
      end

      def register!
        unless grid_class
          raise 'Need to define the grid class first. Use grid_class to do so.'
        end
        unless widgets
          raise 'Need to define at least one widget first. Use widgets to do so.'
        end
        unless to_scope
          raise 'Need to define a scope. Use to_scope to do so'
        end

        Grids::Configuration.register_grid(grid_class, self)

        widgets.each do |widget|
          Grids::Configuration.register_widget(widget, grid_class)
        end
      end

      private

      def url_helpers
        @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
      end
    end
  end
end
