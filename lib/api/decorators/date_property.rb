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

module API
  module Decorators
    module DateProperty
      def self.included(base)
        base.extend ClassMethods
      end

      def self.prepended(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def date_property(name,
                          getter: default_date_getter(name),
                          setter: default_date_setter(name),
                          **args)

          attributes = {
            getter: getter,
            setter: setter,
            render_nil: true
          }

          property name,
                   attributes.merge(args)
        end

        def date_time_property(name,
                               getter: default_date_time_getter(name),
                               **args)

          attributes = {
            getter: getter,
            render_nil: true
          }

          property name,
                   attributes.merge(args)
        end

        private

        def default_date_getter(name)
          ->(represented:, decorator:, **) {
            decorator.datetime_formatter.format_date(represented.send(name), allow_nil: true)
          }
        end

        def default_date_setter(name)
          ->(fragment:, decorator:, **) {
            date = decorator
                   .datetime_formatter
                   .parse_date(fragment,
                               name.to_s.camelize(:lower),
                               allow_nil: true)

            send(:"#{name}=", date)
          }
        end

        def default_date_time_getter(name)
          ->(represented:, decorator:, **) {
            decorator.datetime_formatter.format_datetime(represented.send(name), allow_nil: true)
          }
        end
      end
    end
  end
end
