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

module TestManagement
  class AssistantProvider < ApplicationRecord
    self.table_name = "tm_assistant_providers"

    NAME_LIMIT = 100
    MAX_USER_MODELS = 20

    validates :name, presence: true, length: { maximum: NAME_LIMIT }, uniqueness: { case_sensitive: false }
    validate :user_models_valid

    scope :ordered, -> { order(is_default: :desc).order(Arel.sql("LOWER(tm_assistant_providers.name)"), :id) }

    def self.default_provider
      find_by(is_default: true) || ordered.first
    end

    def self.ensure_default!
      return if exists?(is_default: true)

      ordered.first&.make_default!
    end

    def settings
      {
        "assistant_provider" => preset, "assistant_base_url" => base_url.to_s, "assistant_model" => model.to_s,
        "assistant_api_key_ciphertext" => api_key_ciphertext, "assistant_auth_style" => auth_style,
        "assistant_timeout" => timeout, "assistant_max_tokens" => max_tokens
      }
    end

    def assign_settings(merged) # rubocop:disable Metrics/AbcSize
      merged = merged.to_h.stringify_keys
      self.preset = merged["assistant_provider"].presence || Assistant::AI::Provider::DEFAULT_KEY
      self.base_url = merged["assistant_base_url"].presence
      self.model = merged["assistant_model"].presence
      self.api_key_ciphertext = merged["assistant_api_key_ciphertext"].presence
      self.auth_style = merged["assistant_auth_style"].presence
      self.timeout = merged["assistant_timeout"].presence
      self.max_tokens = merged["assistant_max_tokens"].presence
      self
    end

    def config(model: nil)
      values = settings
      values["assistant_model"] = model if model.present? && selectable_models.include?(model)
      Assistant::ProviderConfig.new(values, name:, provider_id: id)
    end

    def preset_definition
      Assistant::AI::Provider.find(preset)
    end

    def selectable_models
      ([model] + Array(user_models)).map { it.to_s.strip }.compact_blank.uniq
    end

    def user_models=(value)
      list = value.is_a?(String) ? value.split(/[\n,]/) : Array(value)
      super(list.map { it.to_s.strip }.compact_blank.uniq)
    end

    def make_default!
      transaction do
        self.class.where.not(id:).where(is_default: true).update_all(is_default: false)
        update!(is_default: true)
      end
    end

    delegate :configured?, to: :config

    private

    def user_models_valid
      list = Array(user_models)
      errors.add(:user_models, :too_many, count: MAX_USER_MODELS) if list.size > MAX_USER_MODELS
      errors.add(:user_models, :invalid) if list.any? { |m| !m.is_a?(String) || m.length > 255 }
    end
  end
end
