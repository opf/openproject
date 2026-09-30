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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  class LabelsController < ::ApplicationController
    include OpTurbo::ComponentStream
    include PaginationHelper
    include ::Labels::LabelsFeature

    before_action :require_admin
    before_action :require_work_package_labels_feature
    before_action :find_label, only: %i[edit_dialog update deletion_dialog destroy]

    menu_item :labels

    layout "admin"

    def index
      @query = ParamsToQueryService.new(Label, current_user, query_class: Queries::Labels::LabelQuery).call(params)
      @labels = @query.results.paginate(page: page_param, per_page: per_page_param)
    end

    def search
      index

      replace_via_turbo_stream(component: Admin::Labels::ListComponent.new(@labels, query: @query))
      turbo_streams << turbo_stream.push_state(url_for(params.permit(:controller, :filters).merge(action: "index")))

      respond_with_turbo_streams
    end

    def new_dialog
      respond_with_dialog Admin::Labels::DialogComponent.new(label: Label.new)
    end

    def edit_dialog
      respond_with_dialog Admin::Labels::DialogComponent.new(label: @label)
    end

    def create
      result = ::Labels::CreateService
                 .new(user: current_user)
                 .call(label_params)

      result.on_success { redirect_to_label_page(result.result, notice: t(:notice_successful_create)) }

      result.on_failure do
        update_via_turbo_stream(
          component: Admin::Labels::FormComponent.new(label: result.result),
          status: :unprocessable_entity
        )
        respond_with_turbo_streams
      end
    end

    def update
      result = ::Labels::UpdateService
                 .new(user: current_user, model: @label)
                 .call(label_params)

      result.on_success { redirect_to_label_page(result.result, notice: t(:notice_successful_update)) }

      result.on_failure do
        update_via_turbo_stream(
          component: Admin::Labels::FormComponent.new(label: result.result),
          status: :unprocessable_entity
        )
        respond_with_turbo_streams
      end
    end

    def deletion_dialog
      respond_with_dialog Admin::Labels::DeleteDialogComponent.new(@label)
    end

    def destroy
      result = ::Labels::DeleteService
                 .new(user: current_user, model: @label)
                 .call

      if result.success?
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = result.errors.full_messages
      end

      redirect_to admin_labels_path
    end

    private

    def find_label
      @label = Label.find(params.expect(:id))
    end

    def redirect_to_label_page(label, notice:)
      flash[:notice] = notice
      page = Label.page_of(label, per_page: per_page_param)
      redirect_to admin_labels_path(page: page > 1 ? page : nil)
    end

    def label_params
      params.expect(label: [:name])
    end
  end
end
