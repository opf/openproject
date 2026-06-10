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

module ResourcePlannerViews
  module ConfigureStep
    class FooterComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(submit_label: I18n.t(:button_create),
                     dialog_id: ResourcePlannerViews::NewDialogComponent::DIALOG_ID,
                     form_id: ResourcePlannerViews::NewDialogComponent::FORM_ID,
                     footer_id: ResourcePlannerViews::NewDialogComponent::FOOTER_ID,
                     cancel_href: nil)
        super
        @submit_label = submit_label
        @dialog_id = dialog_id
        @form_id = form_id
        @footer_id = footer_id
        @cancel_href = cancel_href
      end

      attr_reader :footer_id
      alias_method :wrapper_key, :footer_id

      def call
        component_wrapper do
          component_collection do |buttons|
            buttons.with_component(cancel_button) { I18n.t(:button_cancel) }

            buttons.with_component(
              Primer::Beta::Button.new(
                scheme: :primary,
                form: @form_id,
                type: :submit
              )
            ) { @submit_label }
          end
        end
      end

      private

      # When a `cancel_href` is passed, Cancel becomes a link that navigates
      # away — used by the new-planner flow so dismissing step 2 lands the
      # user on a page that reflects the just-created planner. Without one,
      # Cancel just dismisses the dialog (standalone "+ Add view" flow).
      def cancel_button
        if @cancel_href
          Primer::Beta::Button.new(tag: :a, href: @cancel_href, mr: 1)
        else
          Primer::Beta::Button.new(data: { "close-dialog-id": @dialog_id }, mr: 1)
        end
      end
    end
  end
end
