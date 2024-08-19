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

module APITokens
  class CreateContract < BaseContract
    attribute :token_name

    validates :token_name, presence: { message: I18n.t("my.access_token.errors.token_name_blank") }
    validate :token_name_is_unique, unless: :token_name_is_blank?

    private

    def token_name_is_blank?
      token_name.blank?
    end

    def token_name_is_unique
      if Token::API.where(user: model.user).any? { |t| t.token_name == model.token_name }
        errors.add(:token_name, :taken, message: I18n.t("my.access_token.errors.token_name_in_use"))
      end
    end
  end
end
