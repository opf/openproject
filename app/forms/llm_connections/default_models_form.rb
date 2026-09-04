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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  class DefaultModelsForm < ApplicationForm
    form do |f|
      # An autocompleter rather than a select: a gateway reports hundreds of
      # models, and every one of them would otherwise be inlined as an option in
      # the page body. decorated: true serialises the list into the element, so
      # this needs no endpoint of its own.
      f.autocompleter(
        name: :default_chat_model_id,
        label: LlmConnection.human_attribute_name(:default_chat_model_id),
        caption: I18n.t("admin.llm_models.defaults.chat_caption"),
        autocomplete_options: {
          decorated: true,
          inputValue: model.default_chat_model_id,
          placeholder: I18n.t("label_none_parentheses")
        }
      ) do |list|
        list.option(label: I18n.t("label_none_parentheses"), value: "",
                    selected: model.default_chat_model_id.blank?)

        default_chat_model_options.each do |model_id|
          list.option(label: option_label(model_id), value: model_id,
                      selected: model.default_chat_model_id == model_id)
        end
      end

      f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
    end

    private

    # The one already chosen is kept regardless of what the server offers today:
    # dropping it would silently blank the field on the next save.
    def default_chat_model_options
      (model.chat_model_ids + [model.default_chat_model_id]).compact_blank.uniq
    end

    # The same friendly name the model table shows; the identifier stays the value.
    def option_label(model_id)
      model_names[model_id].presence || model_id
    end

    def model_names
      @model_names ||= model.models.pluck(:external_id, :display_name).to_h
    end
  end
end
