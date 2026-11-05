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
  module Automation
    class Options
      CASE_MATCHERS = %w[auto reference id].freeze
      SKIPPED_AS = %w[skipped untested blocked ignore].freeze
      FLAKY_AS = %w[passed failed retest].freeze
      CI_KEYS = %w[provider repository runUrl commitSha branch workflow runNumber runAttempt actor pullRequest].freeze
      MODES = %w[new_run new_iteration].freeze

      attr_reader :raw

      def initialize(raw = {})
        @raw = (raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h).deep_stringify_keys
        validate!
      end

      def format = value("format").presence || "auto"
      def run_id = value("runId").presence&.to_s
      def iteration_id = value("iterationId").presence&.to_s
      def external_ref = value("externalRef").presence&.to_s&.first(255)
      def name = value("name").presence&.to_s&.first(255)
      def close_run? = truthy?(value("closeRun"))
      def case_matcher = value("caseMatcher").presence || "auto"
      def create_missing? = truthy?(value("createMissing"))
      def update_references? = value("updateReferences").nil? || truthy?(value("updateReferences"))
      def skipped_as = value("skippedAs").presence || "skipped"
      def flaky_as = value("flakyAs").presence || "passed"
      def status_map = Hash(value("statusMap")).transform_keys { |k| k.to_s.downcase }.transform_values(&:to_s)

      def mode
        raw = value("mode").presence || value("runMode").presence
        raw&.to_s
      end

      def target_run
        value("targetRun").to_s.strip.first(255).presence
      end

      def connection_ref = value("connection").to_s.strip.presence

      def iteration_name
        value("iterationName").to_s.strip.first(255).presence
      end

      def ci
        hash = Hash(value("ci")).stringify_keys
        hash.slice(*CI_KEYS).transform_values { |v| v.to_s.first(1024) }.compact_blank
      end

      def to_h
        {
          "format" => format, "runId" => run_id, "iterationId" => iteration_id, "externalRef" => external_ref,
          "closeRun" => close_run?, "caseMatcher" => case_matcher, "createMissing" => create_missing?,
          "skippedAs" => skipped_as, "flakyAs" => flaky_as, "statusMap" => status_map, "ci" => ci,
          "mode" => mode, "targetRun" => target_run, "connection" => connection_ref, "iterationName" => iteration_name
        }.compact
      end

      def ci_title # rubocop:disable Metrics/AbcSize
        return nil if ci["workflow"].blank? && ci["runNumber"].blank?

        title = "#{ci['workflow'].presence || 'Automation'} ##{ci['runNumber']}".strip
        ref = [ci["branch"], ci["commitSha"]&.first(7)].compact_blank.join("@")
        (ref.present? ? "#{title} · #{ref}" : title).first(255)
      end

      private

      def value(key)
        raw.key?(key) ? raw[key] : raw[key.underscore]
      end

      def truthy?(val)
        [true, "true", "1", 1, "yes", "on"].include?(val)
      end

      def validate! # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        bad(:caseMatcher, CASE_MATCHERS) unless CASE_MATCHERS.include?(case_matcher)
        bad(:skippedAs, SKIPPED_AS) unless SKIPPED_AS.include?(skipped_as)
        bad(:flakyAs, FLAKY_AS) unless FLAKY_AS.include?(flaky_as)
        bad(:format, Parser::FORMATS) unless Parser::FORMATS.include?(format)
        bad(:mode, MODES) if mode && MODES.exclude?(mode)
        raise Error.new(:unprocessable, "iterationId must be a number") if iteration_id && !iteration_id.match?(/\A\d+\z/)

        invalid = status_map.values - TestRunCase::STATUSES - ["ignore"]
        raise Error.new(:unprocessable, "statusMap maps to unknown statuses: #{invalid.join(', ')}") if invalid.any?
      end

      def bad(key, allowed)
        raise Error.new(:unprocessable, "#{key} must be one of: #{allowed.join(', ')}")
      end
    end
  end
end
