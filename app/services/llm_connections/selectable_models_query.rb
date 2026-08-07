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
  # The models offerable to a feature, each with why it is or is not usable.
  #
  # Models are never hidden. Hiding one produces the single support question
  # nobody can answer -- "why can I not pick the model I know works" -- and it is
  # exactly wrong when most verdicts are unknown. Instead each option carries a
  # state the UI renders: selectable, selectable with a warning, or disabled with
  # a reason.
  class SelectableModelsQuery
    Option = Data.define(:model_id, :state, :reasons) do
      def selectable? = state != :unsupported

      def warning? = state == :unknown
    end

    def initialize(connection, feature)
      @connection = connection
      @feature = feature
    end

    def call
      connection.catalogue_model_ids.map { |model_id| option_for(model_id) }
    end

    private

    attr_reader :connection, :feature

    def option_for(model_id)
      states = feature.requires.index_with { |capability| verdict_state(model_id, capability) }

      if states.value?(:unsupported)
        Option.new(model_id:, state: :unsupported,
                   reasons: states.select { |_, s| s == :unsupported }.keys)
      elsif states.value?(:unknown)
        Option.new(model_id:, state: :unknown,
                   reasons: states.select { |_, s| s == :unknown }.keys)
      else
        Option.new(model_id:, state: :supported, reasons: [])
      end
    end

    # No verdict at all is the same as an inconclusive one: we do not know.
    def verdict_state(model_id, capability)
      verdicts.dig(model_id, capability.to_s)&.to_sym || :unknown
    end

    def verdicts
      @verdicts ||= connection.capability_verdicts
                              .pluck(:model_id, :capability, :state)
                              .group_by(&:first)
                              .transform_values { |rows| rows.to_h { |(_, capability, state)| [capability, state] } }
    end
  end
end
