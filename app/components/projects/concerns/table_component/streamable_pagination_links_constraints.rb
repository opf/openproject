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

module Projects
  module Concerns
    module TableComponent
      module StreamablePaginationLinksConstraints
        # @override optional_pagination_options are passed to the pagination_options
        # which are passed to #pagination_links_full in pagination_helper.rb
        #
        # In Turbo streamable components, we need to be able to specify the url_for(action:) so that links are
        # generated in the context of the component index action, instead of any turbo stream actions performing
        # partial updates on the page.
        #
        # params[:url_for_action] is passed to the pagination_options making it's way down to any pagination links
        # that are generated via link_to which calls url_for which uses the params[:url_for_action] to specify
        # the controller action that link_to should use.
        #
        # data-turbo-action="advance" is added to the pagination links ensure links pushState to the browser
        #
        def optional_pagination_options
          super.tap do |options|
            options[:params] = { action: params[:url_for_action] } if params[:url_for_action]
            options[:turbo_action] = "advance"
          end
        end
      end
    end
  end
end
