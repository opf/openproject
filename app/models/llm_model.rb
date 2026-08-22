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

# A model this connection can address.
#
# Rows come from two places: discovered from the server's model list, or entered
# by an administrator. Both are addressed by +external_id+, which is whatever the
# deployment calls the model -- provider-specific and not comparable across
# vendors, which is why it is never used as a lookup key into a public catalogue.
class LlmModel < ApplicationRecord
  # The connection columns that reference a model row, cleared when it goes.
  CONNECTION_DEFAULTS = %i[default_chat_model_id default_embedding_model_id].freeze

  belongs_to :llm_connection

  validates :external_id, presence: true, uniqueness: { scope: :llm_connection_id }

  scope :active, -> { where(active: true) }
  scope :discovered, -> { where(manual: false) }
  scope :manual, -> { where(manual: true) }
  scope :by_identifier, -> { order(:external_id) }

  # What an administrator is willing to have chosen. Distinct from +active+,
  # which the catalogue sync owns and rewrites on every refresh.
  scope :deactivated, -> { where.not(deactivated_at: nil) }
  scope :selectable, -> { active.where(deactivated_at: nil) }

  def deactivated? = deactivated_at.present?

  # Everything that points at a model does so by its identifier string, so a
  # rename has to carry them along or it silently orphans them.
  #
  # Renaming is a correction of the name, not a change of model, which is why
  # this writes directly: a locked binding must not refuse to follow the model
  # it is locked to. The connection defaults reference this row, so they follow
  # on their own.
  def cascade_rename!(previous_external_id)
    return if previous_external_id.blank? || previous_external_id == external_id

    llm_connection.capability_verdicts.where(model_id: previous_external_id).update_all(model_id: external_id)
  end

  # The counterpart of the rename. Verdicts are keyed by the identifier string,
  # not by foreign key, so leaving them behind would silently apply them to a
  # future model re-added under the same name, and a connection default naming a
  # model that no longer exists is one no AI feature could resolve.
  def cascade_delete!
    llm_connection.capability_verdicts.where(model_id: external_id).delete_all
    clear_connection_defaults
  end

  # Offerable in a picker. Note that this is *not* what decides whether a model
  # still resolves: a feature already bound to a deactivated model keeps working,
  # and is surfaced as a warning instead. Switching a row off must never silently
  # break a running feature.
  def selectable? = active? && !deactivated?

  def name = display_name.presence || external_id

  def clear_connection_defaults
    defaults = CONNECTION_DEFAULTS
                 .select { |attribute| llm_connection.public_send(attribute) == id }
                 .index_with(nil)

    llm_connection.update_columns(defaults) if defaults.any?
  end

  # Precedence: what an administrator set, then what the server reported (vLLM
  # and SGLang publish the operator's actual --max-model-len), then what a
  # registry believes about the model in general.
  def context_window
    raw_metadata["admin_context_window"] ||
      raw_metadata["max_model_len"] ||
      raw_metadata["context_window"]
  end

  def admin_context_window = raw_metadata["admin_context_window"]

  def context_window_source
    return :admin if raw_metadata["admin_context_window"].present?
    return :server if raw_metadata["max_model_len"].present?
    return :registry if raw_metadata["context_window"].present?

    nil
  end

  def admin_context_window=(value)
    self.raw_metadata = if value.blank?
                          raw_metadata.except("admin_context_window")
                        else
                          raw_metadata.merge("admin_context_window" => value.to_i)
                        end
  end

  # Capability assertions are stored as verdicts, not columns. These virtual
  # attributes let the edit form treat them as ordinary fields, so the whole
  # screen can be a single Primer form rather than hand-written inputs.
  Llm::Capabilities::CHAT.each do |capability|
    define_method(:"capability_#{capability}") do
      capability_overrides.fetch(capability.to_s) { admin_capability_state(capability) }
    end

    define_method(:"capability_#{capability}=") do |value|
      capability_overrides[capability.to_s] = value.presence
    end
  end

  def capability_overrides = @capability_overrides ||= {}

  # Only an administrator's own assertion is shown as the field's value. A
  # verdict from a probe or a registry is displayed alongside instead, so that
  # saving the form does not silently adopt it as the administrator's.
  def admin_capability_state(capability)
    verdict_for(capability)&.then { |verdict| verdict.source_admin? ? verdict.state : nil }
  end

  # A model is an embedding model when its embeddings verdict says so, and a
  # chat model otherwise. There is no third kind, and no model is both.
  def embedding? = verdict_for(:embeddings)&.state == "supported"

  def model_type = @model_type || (embedding? ? :embedding : :chat)

  def model_type=(value)
    @model_type = value.presence&.to_sym
  end

  def verdict_for(capability)
    llm_connection.capability_verdicts
                  .for_model(external_id)
                  .for_capability(capability)
                  .first
  end

  # Discovered models that the server stopped offering are deactivated rather
  # than deleted, so a binding or verdict pointing at one still has something to
  # name. Manual entries are never deactivated by a refresh: nothing confirms
  # them, so nothing can un-confirm them either.
  def withdrawn? = !active? && !manual?
end
