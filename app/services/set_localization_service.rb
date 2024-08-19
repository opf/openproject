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

class SetLocalizationService
  attr_reader :user, :http_accept_header

  include Redmine::I18n

  def initialize(user, http_accept_header = nil)
    @user = user
    @http_accept_header = http_accept_header
  end

  ##
  # Sets the locale.
  # The locale is determined with the following priority:
  #
  #   1. The language as configured by the user.
  #   2. The first language defined in the Accept-Language header sent by the browser.
  #   3. OpenProject's default language defined in the settings.

  def call
    lang = user_language || header_language || default_language

    set_language_if_valid(lang)
  end

  private

  def user_language
    find_language_or_prefix(user.language) if user.logged?
  end

  def header_language
    return unless http_accept_header

    accept_lang = parse_qvalues(http_accept_header).first
    find_language_or_prefix accept_lang
  end

  def default_language
    Setting.default_language
  end

  # qvalues http header parser
  # code taken from webrick
  def parse_qvalues(value)
    tmp = []
    if value
      parts = value.split(/,\s*/)
      parts.each do |part|
        match = /\A([^\s,]+?)(?:;\s*q=(\d+(?:\.\d+)?))?\z/.match(part)
        if match
          val = match[1]
          q = (match[2] || 1).to_f
          tmp.push([val, q])
        end
      end
      tmp = tmp.sort_by { |_val, q| -q }
      tmp.map! { |val, _q| val }
    end

    tmp
  rescue StandardError
    nil
  end

  def find_language_or_prefix(language)
    return nil unless language

    language = language.to_s.downcase
    find_language(language) || find_language(language.split("-").first)
  end
end
