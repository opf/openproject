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
# Only a single connection is supported today, enforced by a validation rather
# than by the schema: every association is already scoped by +llm_connection_id+.
class LlmConnection < ApplicationRecord
  SINGLETON_IDENTIFIER = "default"

  has_many :health_reports, as: :subject, dependent: :delete_all

  validates :base_url, presence: true
  validate :only_one_connection, on: :create

  class << self
    # The connection record, whether or not it has been persisted yet.
    #
    # Identifying attributes are left unset here and filled in by
    # LlmConnections::SetAttributesService as system changes, so that they do not
    # register as user-made changes to non-writable attributes.
    def instance
      first || new
    end

    # Whether LLM-backed features may run right now. This is the predicate
    # sibling features gate on; see #77783.
    def available?
      OpenProject::FeatureDecisions.llm_connection_active? &&
        Setting.llm_features_enabled? &&
        instance.configured?
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

  def only_one_connection
    return unless self.class.where.not(id:).exists?

    errors.add(:base, :singleton)
  end
end
