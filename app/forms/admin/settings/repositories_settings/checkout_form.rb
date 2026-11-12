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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module Settings
    module RepositoriesSettings
      class CheckoutForm < ApplicationForm
        extend Dry::Initializer

        class DetailsForm < ApplicationForm
          extend Dry::Initializer

          option :vendor

          delegate :simple_format, to: :@view_context

          form do |f|
            f.text_field(
              name: :base_url,
              label: I18n.t(:setting_repository_checkout_base_url),
              type: :url,
              value: Setting.repository_checkout_data[vendor]["base_url"],
              caption: simple_format(I18n.t("repositories.checkout.base_url_text"))
            )

            f.text_area(
              name: :text,
              label: I18n.t(:setting_repository_checkout_text),
              value: Setting.repository_checkout_data[vendor]["text"],
              placeholder: I18n.t("repositories.checkout.default_instructions.#{vendor}"),
              caption: I18n.t("repositories.checkout.text_instructions"),
              rows: 5
            )
          end
        end

        option :vendor, type: proc(&:to_s)

        form do |f|
          f.check_box(
            name: :enabled,
            label: I18n.t(:setting_repository_checkout_display),
            checked: Setting.repository_checkout_data[vendor]["enabled"].to_i > 0,
            caption: I18n.t("repositories.checkout.enable_instructions_text"),
            data: {
              show_when_checked_target: "cause",
              target_name: "#{vendor}_enabled"
            }
          ) do |setting_repository_checkout_check_box|
            setting_repository_checkout_check_box.nested_form(
              classes: ["mt-2", { "d-none" => Setting.repository_checkout_data[vendor]["enabled"].to_i.zero? }],
              data: {
                show_when_checked_target: "effect",
                target_name: "#{vendor}_enabled"
              }
            ) do |builder|
              DetailsForm.new(builder, vendor:)
            end
          end
        end
      end
    end
  end
end
