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

module CustomFields
  module AttributeHelpTextActions
    extend ActiveSupport::Concern

    private

    def update_help_text
      service_class = @attribute_help_text.persisted? ? ::AttributeHelpTexts::UpdateService : ::AttributeHelpTexts::CreateService
      call = service_class
        .new(user: current_user, model: @attribute_help_text)
        .call(attribute_help_text_params_with_attachments)

      if call.success?
        flash[:notice] = t(:notice_successful_update)
        redirect_to show_path
      else
        @attribute_help_text = call.result
        flash.now[:error] = call.message || I18n.t("notice_internal_server_error")
        render_attribute_help_text_form(status: :unprocessable_entity)
      end
    end

    def show_path
      raise SubclassResponsibilityError, "#{self.class} must implement #show_path"
    end

    def render_attribute_help_text_form(status: :ok)
      raise SubclassResponsibilityError, "#{self.class} must implement #render_attribute_help_text_form"
    end

    def find_or_initialize_attribute_help_text
      help_text_class = attribute_help_text_class_for_custom_field
      @attribute_help_text = help_text_class.find_or_initialize_by(
        attribute_name: "custom_field_#{@custom_field.id}"
      )
    end

    def attribute_help_text_class_for_custom_field
      case @custom_field
      when ProjectCustomField
        AttributeHelpText::Project
      when WorkPackageCustomField
        AttributeHelpText::WorkPackage
      when UserCustomField
        AttributeHelpText::User
      else
        raise ArgumentError, "Unsupported custom field type: #{@custom_field.class}"
      end
    end

    def attribute_help_text_params
      params
        .expect(attribute_help_text: [:help_text, :caption, :type, :attribute_name])
        .merge(
          type: attribute_help_text_class_for_custom_field.name,
          attribute_name: "custom_field_#{@custom_field.id}"
        )
    end

    def attribute_help_text_params_with_attachments
      attribute_help_text_params.merge(attachment_params_for_help_text)
    end

    def attachment_params_for_help_text
      attachment_params = permitted_params.attachments.to_h

      if attachment_params.any?
        { attachment_ids: attachment_params.values.map(&:values).flatten }
      else
        {}
      end
    end
  end
end
