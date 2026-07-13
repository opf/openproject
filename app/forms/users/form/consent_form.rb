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

module Users
  module Form
    # The read-only consent status as a regular form section, so it shares the
    # fieldset heading and spacing of the surrounding administration user form.
    class ConsentForm < ApplicationForm
      form do |f|
        f.fieldset_group(title: I18n.t("consent.title"), mb: 3) do |group|
          group.html_content do
            render(consent_status_component)
          end
        end
      end

      def initialize(user:)
        super()
        @user = user
      end

      private

      def consent_status_component
        consent_link = helpers.admin_settings_users_path(anchor: "consent_settings")
        Components::OnOffStatusComponent.new(
          {
            is_on: @user.consented_at.present?,
            on_text: helpers.format_time(@user.consented_at),
            on_description: helpers.link_translate("consent.user_has_consented", links: { consent_settings: consent_link }),
            off_text: I18n.t(:label_never),
            off_description: helpers.link_translate("consent.not_yet_consented", links: { consent_settings: consent_link })
          }
        )
      end
    end
  end
end
