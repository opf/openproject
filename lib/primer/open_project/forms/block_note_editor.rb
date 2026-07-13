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

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class BlockNoteEditor < Primer::Forms::BaseComponent
        include ::OpenProject::StaticRouting::UrlHelpers
        include FrontendAssetHelper
        include BrowserAware

        attr_reader :input,
                    :value,
                    :readonly,
                    :active_user,
                    :attachments_upload_url,
                    :attachments_collection_key,
                    :blocknote_stylesheet_url,
                    :shadow_dom_stylesheet_url,
                    :collaboration_enabled

        delegate :name, to: :@input

        def initialize(input:, value:, readonly:, attachments_upload_url: "", attachments_collection_key: "")
          super()
          @input = input
          @value = value
          @readonly = readonly
          @active_user = {
            id: User.current.id,
            username: User.current.name
          }
          @attachments_upload_url = attachments_upload_url
          @attachments_collection_key = attachments_collection_key
          @blocknote_stylesheet_url = variable_asset_path("blocknote.css")
          @shadow_dom_stylesheet_url = variable_asset_path("styles.css")

          @collaboration_enabled = Setting.real_time_text_collaboration_enabled?
        end
      end
    end
  end
end
