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

module Admin
  class WorkPackageEmbeddingsController < ApplicationController
    layout "admin"

    before_action :require_admin
    before_action :require_feature

    def reindex
      if Llm::IndexWorkPackagesJob.running?
        flash[:warning] = t(".already_running")
      elsif !Llm::Runtime.for(:semantic_search).ready?
        flash[:error] = t(".not_ready")
      else
        Llm::IndexWorkPackagesJob.enqueue_batch
        flash[:notice] = t(".enqueued")
      end

      redirect_to llm_feature_bindings_path, status: :see_other
    end

    private

    def require_feature
      render_404 unless OpenProject::FeatureDecisions.llm_connection_active? &&
                        OpenProject::Llm::Features[:semantic_search].available?
    end
  end
end
