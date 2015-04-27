#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'representable'

module OpenProject::RepresentablePatch
  def self.included(base)
    base.class_eval do
      def self.as_strategy=(strategy)
        raise 'The :as_strategy option should respond to #call?' unless strategy.respond_to?(:call)

        @as_strategy = strategy
      end

      def self.as_strategy
        @as_strategy
      end

      def self.property(name, options = {}, &block)
        options = { as: as_strategy.call(name.to_s) }.merge(options) if as_strategy

        super
      end
    end
  end
end

unless Representable::Decorator.included_modules.include?(OpenProject::RepresentablePatch)
  Representable::Decorator.send(:include, OpenProject::RepresentablePatch)
end
