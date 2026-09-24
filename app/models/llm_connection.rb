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

  scope :active, -> { where(active: true) }

  validates :base_url, presence: true
  validate :base_url_is_absolute_http, if: -> { base_url.present? }
  # The column is NOT NULL and +active_connection+ hands back an unsaved record
  # with no identifier, so without this a save raises NotNullViolation instead of
  # surfacing an error a caller can render.
  validates :identifier, presence: true
  # Not only the contract's: the environment seeder and any direct write reach
  # the model alone, and an unknown format is an UnsupportedFormat raised at read
  # time rather than an error at write time.
  validates :api_format, inclusion: { in: Llm::Adapters::FORMATS }
  validate :single_active_connection, if: :active?
  validate :custom_headers_are_flat_strings

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

  def base_url_is_absolute_http
    uri = URI.parse(base_url)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:base_url, :invalid_url)
  rescue URI::InvalidURIError
    errors.add(:base_url, :invalid_url)
  end

  def single_active_connection
    return unless self.class.active.where.not(id:).exists?

    errors.add(:base, :singleton)
  end

  # The value goes into Faraday's header serialisation unchanged, where a nested
  # hash or a non-string fails at request time rather than at save time.
  def custom_headers_are_flat_strings
    return if custom_headers.blank?

    return errors.add(:custom_headers, :invalid) unless custom_headers.is_a?(Hash)

    return if custom_headers.all? { |name, value| header_pair?(name, value) }

    errors.add(:custom_headers, :invalid)
  end

  def header_pair?(name, value)
    name.is_a?(String) && value.is_a?(String) && !value.match?(/[[:cntrl:]]/)
  end
end
