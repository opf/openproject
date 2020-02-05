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

module OpenProject::TextFormatting::Matchers
  module LinkHandlers
    class Base
      include ::OpenProject::TextFormatting::Truncation
      # used for the work package quick links
      include WorkPackagesHelper
      # Used for escaping helper 'h()'
      include ERB::Util
      # Rails helper
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::TextHelper
      # For route path helpers
      include OpenProject::ObjectLinking
      include OpenProject::StaticRouting::UrlHelpers

      attr_reader :matcher, :context

      def initialize(matcher, context:)
        @matcher = matcher
        @context = context
      end

      ##
      # Allowed prefixes for this matcher
      def self.allowed_prefixes
        []
      end

      def allowed_prefixes
        self.class.allowed_prefixes
      end

      ##
      # Test whether we should try to resolve the given link
      def applicable?
        raise NotImplementedError
      end

      ##
      # Replace the given link with the resource link, depending on the context
      # and matchers.
      # If nil is returned, the link remains as-is.
      def call
        raise NotImplementedError
      end

      def oid
        unless identifier.nil?
          identifier.to_i
        end
      end

      def identifier
        matcher.identifier
      end

      def project
        matcher.project
      end

      ##
      # Call a named route with _path when only_path is true
      # or _url when not.
      #
      # Passes on all remaining params.
      def named_route(name, **args)
        route = if context[:only_path]
          :"#{name}_path"
        else
          :"#{name}_url"
        end

        public_send(route, **args)
      end

      def controller; end
    end
  end
end
