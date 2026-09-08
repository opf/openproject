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
    include Redmine::I18n

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
          disabled: read_only?,
          inputValue: model.default_chat_model_id,
          placeholder: I18n.t("label_none_parentheses")
        }
      ) do |list|
        list.option(label: I18n.t("label_none_parentheses"), value: "",
                    selected: model.default_chat_model_id.blank?)

        default_chat_model_options.each do |llm_model|
          list.option(label: llm_model.name, value: llm_model.id,
                      selected: model.default_chat_model_id == llm_model.id)
        end
      end

      # Only worth asking for once something embeds.
      if embedding_features?
        f.autocompleter(
          name: :default_embedding_model_id,
          label: LlmConnection.human_attribute_name(:default_embedding_model_id),
          caption: embedding_caption,
          autocomplete_options: {
            decorated: true,
            disabled: read_only?,
            inputValue: model.default_embedding_model_id,
            placeholder: I18n.t("label_none_parentheses")
          }
        ) do |list|
          list.option(label: I18n.t("label_none_parentheses"), value: "",
                      selected: model.default_embedding_model_id.blank?)

          default_embedding_model_options.each do |llm_model|
            list.option(label: embedding_option_label(llm_model), value: llm_model.id,
                        selected: model.default_embedding_model_id == llm_model.id)
          end
        end
      end

      f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary) unless read_only?
    end

    private

    def read_only?
      model.configured_from_env?
    end

    # The one already chosen is kept regardless of what the server offers today:
    # dropping it would silently blank the field on the next save.
    def default_chat_model_options
      (model.chat_models + [model.default_chat_model]).compact.uniq
    end

    def embedding_features?
      OpenProject::Llm::Features.for_kind(:embedding).any?
    end

    # Only models actually known to embed. Offering one on the grounds that
    # nothing has ruled it out invites a choice whose failure surfaces much
    # later, at index time.
    def default_embedding_model_options
      (embedding_models + [model.default_embedding_model]).compact.uniq
    end

    def embedding_models
      @embedding_models ||= model.embedding_models
    end

    def embedding_option_label(llm_model)
      return llm_model.name if embedding_models.include?(llm_model)

      I18n.t("admin.llm_models.defaults.embedding_option_unqualified", model: llm_model.name)
    end

    # Says how to make a model eligible when none is, rather than leaving an
    # empty picker with no explanation.
    def embedding_caption
      return I18n.t("admin.llm_models.defaults.embedding_none") if embedding_models.empty?

      link_translate("admin.llm_models.defaults.embedding_caption",
                     links: { docs_url: %i[embeddings_explanation] },
                     external: true)
    end
  end
end
