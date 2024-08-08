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

module Saml
  module Providers
    class RequestAttributesForm < BaseForm
      include Redmine::I18n

      form do |f|
        %i[login mail firstname lastname uid].each do |attribute|
          f.group do |form_group|
            uid = attribute == :uid
            label = uid ? I18n.t("saml.providers.label_uid") : User.human_attribute_name(attribute)
            form_group.text_field(
              name: :"requested_#{attribute}_attribute",
              label: I18n.t("saml.providers.label_requested_attribute_for", attribute: label),
              required: !uid,
              disabled: provider.seeded_from_env?,
              caption: uid ? I18n.t("saml.instructions.request_uid") : nil,
              input_width: :large
            )

            form_group.select_list(
              name: :"requested_#{attribute}_format",
              label: I18n.t("activemodel.attributes.saml/provider.format"),
              input_width: :large,
              disabled: provider.seeded_from_env?,
              caption: link_translate(
                "saml.instructions.documentation_link",
                links: {
                  docs_url: ::OpenProject::Static::Links[:sysadmin_docs][:saml][:href]
                },
                target: "_blank"
              )
            ) do |list|
              Saml::Defaults::ATTRIBUTE_FORMATS.each do |format|
                list.option(label: format, value: format)
              end
            end
          end

          f.separator unless attribute == :uid
        end
      end
    end
  end
end
