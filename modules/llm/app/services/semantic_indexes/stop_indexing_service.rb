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

module SemanticIndexes
  class StopIndexingService < ::BaseServices::BaseCallable
    DISCARD_MESSAGE = "Discarded because the indexing was stopped."
    DISCARDABLE_STATUSES = %i[queued retried scheduled].freeze

    attr_reader :user, :model

    def initialize(user:, model:)
      super()
      @user = user
      @model = model
    end

    protected

    def perform
      return failure(I18n.t(:notice_not_authorized)) unless authorized?

      batch = model.indexing_batch
      model.stop_indexing!
      discard_jobs(batch)

      ServiceResult.success(result: model)
    rescue SemanticIndex::InvalidTransitionError
      failure(I18n.t("admin.semantic_indexes.stop_indexing.not_indexing"))
    end

    private

    def authorized? = user.admin? && user.active?

    def discard_jobs(batch)
      return unless batch

      batch.jobs.each do |job|
        job.discard_job(DISCARD_MESSAGE) if job.status.in?(DISCARDABLE_STATUSES)
      rescue GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError,
             GoodJob::Job::ActionForStateMismatchError
        next
      end
    end

    def failure(message) = ServiceResult.failure(result: model, message:)
  end
end
