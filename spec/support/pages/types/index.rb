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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"

module Pages
  module Types
    class Index < ::Pages::Page
      def path
        "/types"
      end

      def expect_listed(*types)
        headers = page.all(".Box-header .Button-label, .Box-header a")

        expect(headers.map(&:text)).to include(*types.map { |t| canonical_name(t) })
      end

      def click_new
        page.find_test_selector("op-admin-types--button-new", text: "Type").click
      end

      def delete(type)
        within_header(type) { find("action-menu > button").click }

        accept_confirm { click_button I18n.t(:button_delete) }
      end

      private

      def within_header(type)
        header = page.find(".Box-header", text: canonical_name(type))

        within header do
          yield header
        end
      end

      def canonical_name(type)
        type.respond_to?(:name) ? type.name : type
      end
    end
  end
end
