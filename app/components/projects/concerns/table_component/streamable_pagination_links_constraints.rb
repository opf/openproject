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

module Projects
  module Concerns
    module TableComponent
      # For tables that turbo streams re-render from actions other than their index one (e.g. link, unlink):
      # - pagination links are built with url_for, which targets the current action by default, so
      #   url_for_action points them back at the index action;
      # - pagination links are turbo stream requests replacing the table in place, so "advance" pushes
      #   their URL to the browser history, keeping the page on reload and back navigation.
      module StreamablePaginationLinksConstraints
        extend ActiveSupport::Concern

        included do
          options :url_for_action
        end

        def optional_pagination_options
          super.tap do |options|
            options[:params] = { action: url_for_action } if url_for_action
            options[:turbo_action] = "advance"
          end
        end
      end
    end
  end
end
