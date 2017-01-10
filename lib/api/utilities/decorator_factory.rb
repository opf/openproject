#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Utilities
    # When ROAR is tasked with creating embedded representers, it accepts a Decorator class
    # that it will try to instantiate itself. However, we need to transfer contextual information
    # like the current_user into our representers. We will therefore not pass the actual decorator
    # class, but a factory that behaves like one, except for passing hidden information.
    class DecoratorFactory
      def initialize(decorator:, current_user:)
        @decorator = decorator
        @current_user = current_user
      end

      def new(represented)
        @decorator.create(represented, current_user: @current_user)
      end

      # Roar will actually call the prepare method, which delegates to new.
      # N.B. This carries the assumption that the prepare method will never do more than delegate.
      alias_method :prepare, :new
    end
  end
end
