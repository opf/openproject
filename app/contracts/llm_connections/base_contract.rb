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
  # Validations that hold for every write, including provisioning from the
  # environment. Deliberately makes no network request -- see UpdateContract.
  class BaseContract < ModelContract
    attribute :enabled
    attribute :base_url
    attribute :api_key
    attribute :default_chat_model_id
    attribute :default_embedding_model_id

    validates :base_url, presence: true
    # Resolves to the validate_url gem, which defaults to http and https. Plain
    # http is deliberately allowed: an on-premise LLM server on an internal
    # network commonly terminates TLS elsewhere, or not at all.
    validates :base_url, url: { message: :invalid_url }, unless: -> { base_url.blank? }

    validate :enabled_requires_connection
    validate :default_models_offered_by_server
    validate :not_configured_from_env

    def not_configured_from_env
      return unless model.configured_from_env?

      errors.add :base, :configured_via_env
    end

    private

    def enabled_requires_connection
      return unless model.enabled?
      return if model.base_url.present?

      errors.add :enabled, :requires_connection
    end

    # A designated default must be a model the server actually reported. Validated
    # only when it changes, so a catalogue that shrinks underneath a stored
    # selection does not block every unrelated save; the dangling state is
    # surfaced in the UI instead.
    def default_models_offered_by_server
      %i[default_chat_model_id default_embedding_model_id].each do |attribute|
        value = model.public_send(attribute)
        next if value.blank?
        next unless model.changed_attributes.include?(attribute.to_s)
        next if model.available_model_ids.include?(value)

        errors.add attribute, :not_available
      end
    end
  end
end
