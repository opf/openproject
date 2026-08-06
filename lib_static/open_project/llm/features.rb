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

module OpenProject
  module Llm
    class UnknownFeature < StandardError; end

    # A feature that sends requests to the configured LLM server.
    #
    # Features declare the capabilities they need so the administration UI can
    # tell an administrator which models are usable for which job, and so a
    # feature never silently runs against a model that cannot serve it.
    Feature = Data.define(:key, :kind, :requires, :prefers, :overridable, :pinned, :available, :i18n_scope) do
      def available? = available.call

      def chat? = kind == :chat

      def embedding? = kind == :embedding

      def label = I18n.t("label", scope: i18n_scope)

      def caption = I18n.t("caption", scope: i18n_scope, default: nil)
    end

    # The registry of LLM-consuming features.
    #
    # Lives in lib_static because it is populated from initializers, which run
    # before eager loading; constants defined under app/ would be unloaded on a
    # development reload and lose their registrations. This is the same reason
    # OpenProject::FeatureDecisions lives here.
    #
    # Register from config/initializers/llm_features.rb for core features, or
    # from a module's engine:
    #
    #   initializer "openproject_foo.llm_features" do
    #     OpenProject::Llm::Features.register :foo, kind: :chat
    #   end
    module Features
      module_function

      KINDS = %i[chat embedding].freeze

      # Deliberately small. Every capability is a probe, an admin-facing
      # explanation and a maintenance burden, so one is only added when a
      # shipping feature cannot work without it.
      #
      # :embeddings          - the only hard gate. Cannot be emulated: it is a
      #                        different endpoint answering with vectors.
      # :structured_output   - advisory only. Responses are validated and
      #                        repaired regardless, so constrained decoding is
      #                        an optimisation rather than a requirement.
      CAPABILITIES = {
        chat: %i[structured_output].freeze,
        embedding: %i[embeddings].freeze
      }.freeze

      def register(key,
                   kind:,
                   requires: [],
                   prefers: [],
                   overridable: false,
                   pinned: false,
                   available: -> { true },
                   i18n_scope: nil)
        key = key.to_sym
        validate!(key, kind, requires + prefers)

        all[key] = Feature.new(key:, kind:, requires: requires.map(&:to_sym).freeze,
                               prefers: prefers.map(&:to_sym).freeze,
                               overridable:, pinned:, available:,
                               i18n_scope: i18n_scope || "llm.features.#{key}")
      end

      def all = @all ||= {}

      def [](key)
        all.fetch(key.to_sym) { raise UnknownFeature, key.to_s }
      end

      def registered?(key) = all.key?(key.to_sym)

      # Features whose own toggle is on. A feature that is switched off keeps its
      # stored binding: flipping a flag must not lose an administrator's choice.
      def available = all.values.select(&:available?)

      def for_kind(kind) = available.select { |feature| feature.kind == kind }

      def validate!(key, kind, capabilities)
        raise ArgumentError, "unknown kind #{kind.inspect}" unless KINDS.include?(kind)
        raise ArgumentError, "LLM feature #{key} is already registered" if all.key?(key)

        unknown = capabilities.map(&:to_sym) - CAPABILITIES.fetch(kind)
        return if unknown.empty?

        raise ArgumentError, "#{unknown.join(', ')} not valid for a #{kind} feature"
      end
    end
  end
end
