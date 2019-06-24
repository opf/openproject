#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
    class << self
      def grid_class(name_string = nil)
        if name_string
          @grid_class = name_string
        end

        @grid_class
      end

      def to_scope(path = nil)
        if path
          @to_scope = path
        end

        @to_scope
      end

      def widgets(*widgets)
        if widgets.any?
          @widgets = widgets
        end

        @widgets
      end

      def widget_strategy(widget_name, &block)
        @widget_strategies ||= {}

        if block_given?
          @widget_strategies[widget_name.to_s] = Class.new(Grids::Configuration::WidgetStrategy, &block)
        end

        @widget_strategies[widget_name.to_s] ||= Grids::Configuration::WidgetStrategy
      end

      def defaults(proc = nil)
        # This is called during code load, which
        # may not have the table available.
        return unless Grids::Widget.table_exists?

        if proc
          @defaults = proc
        else
          params = @defaults.call
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
        Array(url_helpers.send(@to_scope))
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

      def register!
        unless @grid_class
          raise 'Need to define the grid class first. Use grid_class to do so.'
        end
        unless @widgets
          raise 'Need to define at least one widget first. Use widgets to do so.'
        end
        unless @to_scope
          raise 'Need to define a scope. Use to_scope to do so'
        end

        Grids::Configuration.register_grid(@grid_class, self)

        widgets.each do |widget|
          Grids::Configuration.register_widget(widget, @grid_class)
        end
      end

      private

      def url_helpers
        @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
      end
    end
  end
end
