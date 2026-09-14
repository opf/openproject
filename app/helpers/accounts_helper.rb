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

module AccountsHelper
  class Footer
    include OpenProject::TextFormatting

    attr_reader :source

    def initialize(source)
      @source = source
    end

    def to_html
      format_text source
    end
  end

  def login_field(form)
    form.text_field :login, size: 25, required: true
  end

  def email_field(form)
    form.text_field :mail, required: true, readonly: !registration_mail_editable?
  end

  ##
  # An invited user activates an existing account, so they may only keep the address the
  # administrator invited them with unless users are allowed to change their email address.
  # Self-registering users always pick their own address.
  def registration_mail_editable?
    Setting.user_can_change_email? || @user.nil? || @user.new_record? # rubocop:disable Rails/HelperInstanceVariable
  end

  ##
  # Hide the email field in the registration form if the `email_login` setting
  # is active. However, if an auth source is present, do show it independently from
  # the `email_login` setting as we can't say if the auth source's login is the email address.
  def registration_show_email?
    !Setting.email_login? || @user.ldap_auth_source_id.present? # rubocop:disable Rails/HelperInstanceVariable
  end

  def registration_footer
    footer = registration_footer_for lang: I18n.locale.to_s

    Footer.new(footer).to_html if footer
  end

  ##
  # Gets the registration footer in the given language from the settings.
  #
  # @param lang [String] ISO 639-1 language code (e.g. 'en', 'de')
  def registration_footer_for(lang:)
    Setting.registration_footer[lang.to_s].presence
  end
end
