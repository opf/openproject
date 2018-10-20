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

require 'support/pages/page'

module Pages
  module Types
    class Index < ::Pages::Page
      def path
        "/types"
      end

      def expect_listed(*types)
        rows = page.all 'td.timelines-pet-name'

        expected = types.map { |t| canonical_name(t) }

        expect(rows.map(&:text)).to eq(expected)
      end

      def expect_successful_create
        expect_notification message: I18n.t(:notice_successful_create)
      end

      def expect_successful_update
        expect_notification message: I18n.t(:notice_successful_update)
      end

      def click_new
        within '.toolbar-items' do
          click_link 'Type'
        end
      end

      def click_edit(type)
        within_row(type) do
          click_link canonical_name(type)
        end
      end

      def delete(type)
        within_row(type) do
          click_link 'Delete'
        end

        accept_alert_dialog!
      end

      private

      def within_row(type)
        row = page.find('table tr', text: canonical_name(type))

        within row do
          yield row
        end
      end

      def canonical_name(type)
        type.respond_to?(:name) ? type.name : type
      end

      def notification_type
        :rails
      end
    end
  end
end
