# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module My
  module AccessToken
    class NewAccessTokenComponent < ApplicationComponent
      include OpTurbo::Streamable

      options dialog_id: "my--new-access-token-component",
              dialog_body_id: "my--new-access-token-body-component"

      private

      def title
        I18n.t("my.access_token.new_access_token_dialog_title")
      end

      def text
        I18n.t("my.access_token.new_access_token_dialog_text")
      end

      def attention_text
        I18n.t("my.access_token.new_access_token_dialog_attention_text")
      end

      def show_button_text
        I18n.t("my.access_token.new_access_token_dialog_show_button_text")
      end

      def cancel_button_text
        I18n.t("button_cancel")
      end

      def submit_button_text
        I18n.t("my.access_token.new_access_token_dialog_submit_button_text")
      end
    end
  end
end
