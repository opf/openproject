# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module OAuth
  module Applications
    class TableComponent < ::TableComponent
      class << self
        def row_class
          ::OAuth::Applications::RowComponent
        end
      end

      def initial_sort
        %i[id asc]
      end

      def sortable?
        false
      end

      def columns
        headers.map(&:first)
      end

      def inline_create_link
        link_to new_oauth_application_path,
                aria: { label: t('oauth.application.new') },
                class: 'wp-inline-create--add-link',
                title: t('oauth.application.new') do
          helpers.op_icon('icon icon-add')
        end
      end

      def empty_row_message
        I18n.t :no_results_title_text
      end

      def headers
        [
          ['name', { caption: ::Doorkeeper::Application.human_attribute_name(:name) }],
          ['owner', { caption: ::Doorkeeper::Application.human_attribute_name(:owner) }],
          ['client_credentials', { caption: I18n.t('oauth.client_credentials') }],
          ['redirect_uri', { caption: ::Doorkeeper::Application.human_attribute_name(:redirect_uri) }],
          ['confidential', { caption: ::Doorkeeper::Application.human_attribute_name(:confidential) }]
        ]
      end
    end
  end
end
