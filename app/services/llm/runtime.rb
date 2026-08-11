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

module Llm
  # Answers "which model should this feature use, and can it run right now?".
  #
  # The single place model resolution happens, so that every feature agrees on
  # what an unset value means:
  #
  #   per-item override -> feature binding -> connection default -> unbound
  #
  # A blank value at any level means "inherit from the level below".
  class Runtime
    # :ready            - go ahead
    # :feature_disabled - the feature's own toggle is off
    # :no_connection    - no LLM server configured, or AI switched off globally
    # :unbound          - nothing has chosen a model for this feature yet
    # :model_missing    - the chosen model is not in the server's catalogue
    # :incapable        - the chosen model is known not to support what is needed
    Resolution = Data.define(:feature, :connection, :model_id, :status, :missing_capabilities) do
      def ready? = status == :ready

      # A chat builder for the resolved model.
      #
      # Note that RubyLLM enforces none of the feature's declared requirements:
      # Chat#with_schema performs no capability check, and a model absent from
      # RubyLLM's registry is described by Model::Info.default, which claims
      # structured output, vision and function calling for everything. The
      # capability verdicts consulted in #call above are the only real gate.
      #
      # @return [RubyLLM::Chat]
      def chat(**)
        ensure_usable!(:chat)
        session(**).chat(model_id)
      end

      # @return [RubyLLM::Embedding]
      def embed(input, dimensions: nil, **)
        ensure_usable!(:embedding)
        session(**).embed(input, model: model_id, dimensions:)
      end

      # @return [Llm::Session]
      def session(**)
        Llm::Session.for(connection, **)
      end

      private

      # Features are resolved by kind, so asking a chat feature to embed means a
      # caller has confused two features -- a bug, not a configuration problem.
      def ensure_usable!(kind)
        raise Llm::Errors::NotReady, status unless ready?
        return if feature.public_send(:"#{kind}?")

        raise Llm::Errors::NotReady, :wrong_kind
      end
    end

    class << self
      # @param feature_key [Symbol] a key registered with OpenProject::Llm::Features
      # @param override [String, nil] a per-item model choice, e.g. one stored on
      #   a description assistant action. Blank means inherit.
      def for(feature_key, override: nil)
        new(OpenProject::Llm::Features[feature_key], override:).call
      end
    end

    def initialize(feature, override: nil)
      @feature = feature
      @override = override
    end

    def call
      return resolution(:feature_disabled) unless feature.available?
      return resolution(:no_connection) unless LlmConnection.available?

      model_id = resolved_model_id
      return resolution(:unbound) if model_id.blank?
      return resolution(:model_missing, model_id:) unless connection.available_model_ids.include?(model_id)

      missing = unsupported_capabilities(model_id)
      return resolution(:incapable, model_id:, missing_capabilities: missing) if missing.any?

      resolution(:ready, model_id:)
    end

    private

    attr_reader :feature, :override

    def connection
      @connection ||= LlmConnection.instance
    end

    def resolved_model_id
      override.presence || binding_model_id || connection_default
    end

    def binding_model_id
      connection.feature_bindings.find_by(feature_key: feature.key.to_s)&.model_id.presence
    end

    def connection_default
      feature.embedding? ? connection.default_embedding_model_id : connection.default_chat_model_id
    end

    # Only a definite :unsupported blocks. An :unknown verdict -- which is the
    # normal state for a server that reports nothing about its models -- is
    # surfaced in the UI as a warning but never prevents a call.
    def unsupported_capabilities(model_id)
      return [] if feature.requires.empty?

      blocking = connection.capability_verdicts
                           .for_model(model_id)
                           .where(capability: feature.requires.map(&:to_s), state: "unsupported")

      blocking.pluck(:capability).map(&:to_sym)
    end

    def resolution(status, model_id: nil, missing_capabilities: [])
      Resolution.new(feature:, connection: status == :feature_disabled ? nil : connection,
                     model_id:, status:, missing_capabilities:)
    end
  end
end
