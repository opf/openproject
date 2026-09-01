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

# The connection to an OpenAI-API-compatible LLM server.
#
# Only one connection may be active at a time, capped by a validation and a
# partial unique index. +active+ picks the connection features resolve against.
#
# Callers reach that connection through +active_connection+, so lifting the cap
# is a change to the validation and the index.
class LlmConnection < ApplicationRecord
  DEFAULT_IDENTIFIER = "default"

  has_many :health_reports, as: :subject, dependent: :delete_all

  # Written through to Setting.llm_features_enabled by
  # LlmConnections::UpdateService, so the form can offer the instance-wide
  # switch beside the connection's own fields.
  attribute :llm_features_enabled, :boolean, default: -> { Setting.llm_features_enabled? }

  scope :active, -> { where(active: true) }

  validates :base_url, presence: true
  validate :single_active_connection, if: :active?

  class << self
    # Identifying attributes are left unset here and filled in by
    # LlmConnections::SetAttributesService as system changes, so that they do not
    # register as user-made changes to non-writable attributes.
    def active_connection
      active.first || new(active: true)
    end

    # Whether LLM-backed features may run right now. This is the predicate
    # sibling features gate on; see #77783.
    def available?
      OpenProject::FeatureDecisions.llm_connection_active? &&
        Setting.llm_features_enabled? &&
        active_connection.configured?
    end
  end

  # A key assigned but not saved, as after a failed update, is not stored.
  def api_key_stored? = persisted? && api_key_in_database.present?

  # Deliberately does not consider +last_connected_at+: a connection provisioned
  # from the environment is never probed, and must still count as configured.
  def configured?
    base_url.present?
  end

  def server_flavour
    options["server_flavour"].presence&.to_sym
  end

  private

  def single_active_connection
    return unless self.class.active.where.not(id:).exists?

    errors.add(:base, :singleton)
  end
end
