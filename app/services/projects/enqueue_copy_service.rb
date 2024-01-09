#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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

    def perform(params)
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

      Projects::CopyService
        .new(user:, source:)
        .call(test_params)
    end

    ##
    # Schedule the project copy job
    def schedule_copy_job(params)
      CopyProjectJob.perform_later(user_id: user.id,
                                   source_project_id: source.id,
                                   target_project_params: params[:target_project_params],
                                   associations_to_copy: params[:only].to_a,
                                   send_mails: ActiveRecord::Type::Boolean.new.cast(params[:send_notifications]))
    end
  end
end
