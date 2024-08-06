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

module ::UserConsentHelper
  def consent_param?
    params[:consent_check].present?
  end

  def user_consent_required?
    # Ensure consent is enabled and a text is provided
    Setting.consent_required? && consent_configured?
  end

  ##
  # Gets consent instructions.
  #
  # @param locale [String] ISO-639-1 code for the desired locale (e.g. de, en, fr).
  #                        `I18n.locale` is set for each request individually depending
  #                        among other things on the user's Accept-Language headers.
  # @return [String] Instructions in the respective language.
  def user_consent_instructions(locale)
    all = Setting.consent_info
    all.fetch(locale.to_s) { all.values.first }
  end

  def consent_checkbox_label(locale: I18n.locale)
    I18n.t("consent.checkbox_label", locale:)
  end

  private

  def consent_configured?
    if Setting.consent_info.count == 0
      Rails.logger.error "Instance is configured to require consent, but no consent_info has been set."

      false
    else
      true
    end
  end
end
