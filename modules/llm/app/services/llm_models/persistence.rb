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
module LlmModels
  module Persistence
    IDENTIFIER_INDEX = "index_llm_models_on_llm_connection_id_and_external_id"

    private

    def persist(service_result)
      llm_model = service_result.result
      pin_type = type_chosen?

      begin
        ActiveRecord::Base.transaction(requires_new: true) do
          super.tap { |call| after_save(llm_model, pin_type:) if call.success? }
        end
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
        add_uniqueness_error(llm_model, e)
        ServiceResult.failure(result: llm_model, errors: llm_model.errors)
      end
    end

    def after_save(llm_model, pin_type:)
      apply_capabilities(llm_model, pin_type:)
    end

    def type_chosen?
      params[:model_type].present?
    end

    # Two administrators saving the same free identifier both pass the
    # uniqueness validation, and only the index rejects the second. A rename also
    # carries verdicts along, and those may collide with verdicts left under the
    # new identifier by a model that no longer exists, and an assertion may meet a
    # verdict detection wrote meanwhile.
    def add_uniqueness_error(llm_model, error)
      llm_model.errors.add(:external_id, identifier_taken?(error) ? :taken : :conflicting_capabilities)
    end

    def identifier_taken?(error)
      error.cause.try(:result)&.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME) == IDENTIFIER_INDEX
    end

    # A capability is only touched when its key was submitted: absent is not
    # blank, and blank withdraws the administrator's assertion.
    def apply_capabilities(llm_model, pin_type:)
      embedding = params[:model_type].to_s == "embedding"
      assert(llm_model, :embeddings, embedding ? "supported" : "unsupported") if pin_type

      Llm::Capabilities::CHAT.each do |capability|
        next unless embedding || params.key?(:"capability_#{capability}")

        assert(llm_model, capability, embedding ? nil : params[:"capability_#{capability}"].presence)
      end
    end

    def assert(llm_model, capability, state)
      verdict = llm_model.llm_connection.capability_verdicts
                         .find_or_initialize_by(model_id: llm_model.external_id, capability: capability.to_s)

      if state.blank?
        verdict.destroy! if verdict.persisted? && verdict.source_admin?
      else
        verdict.update!(state:, source: "admin", checked_at: Time.current)
      end
    end
  end
end
