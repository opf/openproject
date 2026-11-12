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

module API
  module Decorators
    class Collection < ::API::Decorators::Single
      include API::Utilities::UrlHelper

      def initialize(models, total, self_link:, current_user:, groups: nil)
        @total = total
        @groups = groups
        @self_link = self_link

        super(models, current_user:)
      end

      class << self
        attr_writer :element_decorator_class

        def element_decorator_class
          @element_decorator_class ||= begin
            unless name.end_with?("CollectionRepresenter")
              raise ArgumentError,
                    "Can't deduce representer name from #{name}, please specify it with `element_decorator ClassName`"
            end

            name.gsub("CollectionRepresenter", "Representer")
                .constantize
          end
        end

        def element_decorator(klass)
          self.element_decorator_class = klass
        end

        def to_eager_load
          super || element_decorator_class.to_eager_load
        end

        def to_preload
          super || element_decorator_class.to_preload
        end
      end

      def element_decorator
        self.class.element_decorator_class
      end

      link :self do
        { href: @self_link }
      end

      property :total, getter: ->(*) { @total }, exec_context: :decorator
      property :count, getter: ->(*) { represented.to_a.size }, exec_context: :decorator

      property :groups,
               exec_context: :decorator,
               render_nil: false

      collection :elements,
                 getter: ->(*) {
                   represented.map do |model|
                     element_decorator.create(model, current_user:)
                   end
                 },
                 exec_context: :decorator,
                 embedded: true

      def _type
        "Collection"
      end

      attr_reader :groups
    end
  end
end
