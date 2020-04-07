#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'
require 'support/pages/work_packages/abstract_work_package_create'
require_relative '../../components/bcf_details_viewpoints'

module Pages
  module BCF
    class CreateSplit < ::Pages::AbstractWorkPackageCreate
      include ::Components::BcfDetailsViewpoints

      attr_accessor :project,
                    :model_id,
                    :type_id,
                    :view_route

      def initialize(project:, model_id: nil, type_id: nil)
        super(project: project)
        self.model_id = model_id
        self.type_id = type_id
        self.view_route = :split
      end

      # Override delete viewpoint since we don't have confirm alert
      def delete_viewpoint_at_position(index)
        page.all('.icon-delete.ngx-gallery-icon-content')[index].click
      end

      def path
        bcf_project_frontend_path(project, "#{view_route}/create_new")
      end

      def expect_current_path
        expect(page)
          .to have_current_path(path, ignore_query: true)
      end

      def container
        find("wp-new-split-view")
      end

      private

      def default?
        model_id.nil?
      end
    end
  end
end
