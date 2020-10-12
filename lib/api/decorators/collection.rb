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
    class Collection < ::API::Decorators::Single
      include API::Utilities::UrlHelper

      def initialize(models, total, self_link, current_user:)
        @total = total
        @self_link = self_link

        super(models, current_user: current_user)
      end

      class_attribute :element_decorator_class

      def self.element_decorator(klass)
        self.element_decorator_class = klass
      end

      def element_decorator
        self.class.element_decorator_class
      end

      link :self do
        { href: @self_link }
      end

      property :total, getter: ->(*) { @total }, exec_context: :decorator
      property :count, getter: ->(*) { count }

      collection :elements,
                 getter: ->(*) {
                   represented.map do |model|
                     element_decorator.create(model, current_user: current_user)
                   end
                 },
                 exec_context: :decorator,
                 embedded: true

      def _type
        'Collection'
      end
    end
  end
end
