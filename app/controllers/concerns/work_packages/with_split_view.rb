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

module WorkPackages
  module WithSplitView
    extend ActiveSupport::Concern

    included do
      helper_method :split_view_base_route
    end

    def split_view_work_package_id
      params[:work_package_id].to_i
    end

    def close_split_view
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("work-package-details-#{split_view_work_package_id}"),
            turbo_stream.push_state(url: split_view_base_route),
            turbo_stream.set_title(title: helpers.page_title(I18n.t("js.notifications.title")))
          ]
        end
        format.html do
          redirect_to split_view_base_route
        end
      end
    end

    def respond_to_with_split_view(&format_block)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("content-bodyRight", helpers.split_view_instance.render_in(view_context)),
            turbo_stream.push_state(url: request.fullpath)
          ]
        end

        yield(format) if format_block
      end
    end
  end
end
