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

module Projects
  class EnqueueCopyService < ::BaseServices::BaseCallable
    attr_reader :source, :user

    def initialize(user:, model: nil, **)
      @user = user
      @source = model
    end

    private

    def perform
      call = test_copy(params)

      if call.success?
        ServiceResult.success result: schedule_copy_job(params)
      else
        call
      end
    end

    ##
    # Tests whether the copy can be performed
    def test_copy(params)
      test_params = params.merge(attributes_only: true)
      contract_options = { skip_custom_field_validation: params[:skip_custom_field_validation] }
      Projects::CopyService
        .new(user:, source:, contract_options:)
        .call(test_params)
    end

    ##
    # Schedule the project copy job
    def schedule_copy_job(params)
      job = nil
      GoodJob::Batch.enqueue(on_finish: SendCopyProjectStatusEmailJob, user:, source_project: source) do
        job = CopyProjectJob.perform_later(target_project_params: params[:target_project_params],
                                           copy_from_template: params.dig(:target_project_params, :template).present?,
                                           associations_to_copy: params[:only].to_a,
                                           skip_custom_field_validation: params[:skip_custom_field_validation],
                                           send_mails: ActiveRecord::Type::Boolean.new.cast(params[:send_notifications]))
      end
      job
    end
  end
end
