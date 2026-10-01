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

# This components renders a dialog to confirm the deletion of a project from a storage.
module My
  module AccessToken
    class APITokensSectionComponent < ::ApplicationComponent
      include OpTurbo::Streamable
      include Redmine::I18n

      attr_reader :tokens, :token_type

      def initialize(tokens:, token_type:)
        super

        @tokens = tokens
        @token_type = token_type
      end

      private

      def wrapper_key
        "#{token_type.model_name.element}-token-component"
      end

      def i18n_scope
        [:my_account, :access_tokens, token_type.model_name.i18n_key]
      end

      def token_available?
        case token_type.to_s
        when "Token::API" then Setting.api_tokens_enabled?
        when "Token::ICalMeeting" then Setting.ical_enabled?
        when "Token::RSS" then Setting.feeds_enabled?
        else raise ArgumentError, "Unknown token type: #{token_type}"
        end
      end

      def show_add_button?
        return @tokens.empty? if token_type.to_s == "Token::RSS"

        true
      end

      def add_button_icon
        case token_type.to_s
        when "Token::RSS", "Token::ICalMeeting" then :rss
        else :plus
        end
      end

      def add_button_method
        case token_type.to_s
        when "Token::RSS" then :post
        else :get
        end
      end

      def add_button_path
        case token_type.to_s
        when "Token::RSS" then generate_rss_key_my_access_tokens_path
        else dialog_my_access_tokens_path(token_type: token_type.model_name.element)
        end
      end
    end
  end
end
