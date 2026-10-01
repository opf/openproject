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

module Users::Invitation::ProjectStep
  class FooterComponent < ApplicationComponent
    include ApplicationHelper
    include OpenProject::FormTagHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def wrapper_key
      Users::Invitation::DialogComponent::FOOTER_ID
    end

    def call
      component_wrapper do
        component_collection do |modal_footer|
          modal_footer.with_component(
            Primer::Beta::Button.new(
              data: { "close-dialog-id": Users::Invitation::DialogComponent::DIALOG_ID },
              mr: 1
            )
          ) do
            I18n.t(:button_cancel)
          end

          modal_footer.with_component(
            Primer::Beta::Button.new(
              scheme: :primary,
              form: Users::Invitation::DialogComponent::FORM_ID,
              type: :submit
            )
          ) do
            I18n.t(:button_continue)
          end
        end
      end
    end
  end
end
