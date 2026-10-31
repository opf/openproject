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

class SemanticIndex < ApplicationRecord
  class InvalidTransitionError < StandardError; end

  INDEXABLE_STATES = %w[not_indexed failed ready].freeze
  PARAMETERS = %w[model_id embedding_vector_dimensions context_token_length].freeze

  has_many :llm_feature_bindings, dependent: :restrict_with_error

  enum :state, {
    not_indexed: "not_indexed",
    indexing: "indexing",
    ready: "ready",
    failed: "failed"
  }

  validates :title, presence: true
  validates :model_id, presence: true, length: { maximum: LlmModel::MAX_EXTERNAL_ID_LENGTH }
  validates :embedding_vector_dimensions,
            numericality: { only_integer: true, greater_than: 0,
                            less_than_or_equal_to: WorkPackageEmbedding::DIMENSIONS }
  validates :context_token_length, numericality: { only_integer: true, greater_than: 0 }

  def self.semantic_search_binding
    semantic_search_bindings.first_or_initialize
  end

  def self.semantic_search_bindings
    LlmConnection.active_connection.feature_bindings.where(feature_key: "semantic_search")
  end

  def self.active
    joins(:llm_feature_bindings).merge(semantic_search_bindings).first
  end

  def self.active_id
    semantic_search_bindings.pick(:semantic_index_id)
  end

  def active? = persisted? && self.class.active_id == id

  def indexing_batch
    return if indexing_batch_id.nil?

    GoodJob::BatchRecord.find_by(id: indexing_batch_id)
  end

  def indexable? = INDEXABLE_STATES.include?(state)

  def parameters_locked? = !not_indexed?

  def start_indexing!
    with_lock do
      raise InvalidTransitionError, "cannot start indexing from #{state}" unless indexable?

      update!(state: :indexing, error_message: nil)
    end
  end

  def stop_indexing!
    transition_from_indexing!(state: :not_indexed, error_message: nil)
  end

  def finish_indexing!
    transition_from_indexing!(state: :ready)
  end

  def fail_indexing!(error_message)
    transition_from_indexing!(state: :failed, error_message:)
  end

  private

  def transition_from_indexing!(**attributes)
    with_lock do
      raise InvalidTransitionError, "cannot finish indexing from #{state}" unless indexing?

      update!(**attributes)
    end
  end
end
