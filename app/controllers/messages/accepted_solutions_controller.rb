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

module Messages
  class AcceptedSolutionsController < ApplicationController
    include OpTurbo::ComponentStream

    before_action :find_message

    # Either the topic's author or edit_messages may do this, which the permission map cannot express.
    no_authorization_required! :create, :destroy

    def create
      accept(true)
    end

    def destroy
      accept(false)
    end

    private

    def accept(accepted)
      call = Messages::UpdateService
        .new(user: current_user, model: @message, contract_class: Messages::AcceptSolutionContract)
        .call(accepted_solution: accepted)
      return render_403 if call.failure?

      topic = @message.parent
      work_packages = Messages::CreatedWorkPackagesQuery.for_messages([@message, topic], user: current_user)
      replace_via_turbo_stream(component: post_component(@message, work_packages, focus: true))
      replace_via_turbo_stream(component: post_component(topic, work_packages))
      replace_via_turbo_stream(component: Messages::TopicSummaryComponent.new(topic:))
      respond_with_turbo_streams
    end

    def post_component(message, work_packages, focus: false)
      Messages::PostComponent.new(message:, work_packages: work_packages.fetch(message.id, []), focus:)
    end

    def find_message
      @message = Message.visible(current_user).where(forum_id: params.expect(:forum_id)).find(params.expect(:topic_id))
    end
  end
end
