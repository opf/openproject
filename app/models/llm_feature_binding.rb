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

# Which model a registered feature uses.
#
# One row per feature, not per binding: rows are reconciled against the registry
# and are never destroyed when a feature deregisters, so flipping a feature flag
# does not lose the administrator's choice.
class LlmFeatureBinding < ApplicationRecord
  belongs_to :llm_connection

  validates :feature_key, presence: true, uniqueness: { scope: :llm_connection_id }
  validate :feature_registered
  validate :pinned_model_unchanged

  def feature
    OpenProject::Llm::Features[feature_key]
  rescue OpenProject::Llm::UnknownFeature
    nil
  end

  # NULL means "use the connection default for this kind of model".
  def resolved_model_id
    model_id.presence || default_model_id
  end

  def inherits_default? = model_id.blank?

  # Derived, never stored. A status column would be a cache with no invalidation
  # trigger, and would be stale exactly when it matters -- right after the remote
  # catalogue changed.
  def dangling?
    resolved = resolved_model_id
    resolved.present? && llm_connection.available_model_ids.exclude?(resolved)
  end

  def locked? = locked_at.present?

  private

  def default_model_id
    return if feature.nil?

    feature.embedding? ? llm_connection.default_embedding_model_id : llm_connection.default_chat_model_id
  end

  def feature_registered
    return if feature.present?

    errors.add(:feature_key, :not_registered)
  end

  # Vectors written under one embedding model are meaningless under another, and
  # the dimension count is baked into the index, so a locked binding can only be
  # changed by an explicit re-index.
  def pinned_model_unchanged
    return unless locked? && model_id_changed?

    errors.add(:model_id, :locked)
  end
end
