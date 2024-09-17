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

module ErrorMessageHelper
  include ActionView::Helpers::OutputSafetyHelper

  def error_messages_for(object)
    object = instance_variable_get(:"@#{object}") unless object.respond_to?(:to_model)
    object = convert_to_model(object)
    return unless object

    render_error_messages_partial(object.errors, object)
  end

  def render_error_messages_partial(errors, object)
    return "" if errors.empty?

    base_error_messages = errors.full_messages_for(:base)
    fields_error_messages = errors.full_messages - base_error_messages

    render partial: "common/validation_error",
           locals: { base_error_messages:,
                     fields_error_messages:,
                     object_name: object.class.model_name.human }
  end

  def text_header_invalid_fields(base_error_messages, fields_error_messages)
    return if fields_error_messages.blank?

    i18n_key = base_error_messages.present? ? "errors.header_additional_invalid_fields" : "errors.header_invalid_fields"
    t(i18n_key, count: fields_error_messages.count)
  end

  def list_of_messages(messages)
    return if messages.blank?

    messages = messages.map { |message| tag.li message }
    tag.ul { safe_join(messages, "\n") }
  end
end
