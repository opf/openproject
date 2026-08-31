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

module EnterpriseTrials
  class Form < ApplicationForm
    form do |f|
      f.text_field(
        name: :company,
        label: I18n.t("activerecord.attributes.enterprise_trial.company"),
        required: true
      )

      f.group(layout: :horizontal) do |g|
        g.text_field(
          name: :firstname,
          label: I18n.t("activerecord.attributes.user.first_name"),
          required: true
        )

        g.text_field(
          name: :lastname,
          label: I18n.t("activerecord.attributes.user.last_name"),
          required: true
        )
      end

      f.text_field(
        name: :email,
        label: I18n.t("attributes.email"),
        required: true
      )

      f.text_field(
        name: :domain,
        value: Setting.host_name,
        label: EnterpriseTrial.human_attribute_name(:domain),
        caption: I18n.t("ee.trial.domain_caption"),
        disabled: true
      )

      f.check_box(
        required: true,
        label: helpers.link_translate("ee.trial.consent",
                                      links: {
                                        tos_url: %i[terms_of_service],
                                        privacy_url: %i[data_privacy]
                                      }),
        name: :general_consent
      )

      f.check_box(
        required: false,
        label: helpers.link_translate("ee.trial.receive_newsletter",
                                      links: {
                                        newsletter_url: %i[newsletter]
                                      }),
        name: :newsletter_consent
      )
    end
  end
end
