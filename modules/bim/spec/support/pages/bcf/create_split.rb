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

module Pages
  module BCF
    class CreateSplit < ::Pages::AbstractWorkPackageCreate
      attr_accessor :project,
                    :model_id,
                    :type_id

      def initialize(project, model_id: nil, type_id: nil)
        super(project: project)
        self.model_id = model_id
        self.type_id = type_id
      end

      def path
        path = if default?
                 defaults_ifc_models_project_ifc_models_path(project)
               else
                 ifc_models_project_ifc_model(project, id: model_id)
               end + '/new'

        query = if type_id
                  "?type=#{type_id}"
                end

        path + query
      end

      def expect_current_path
        expect(page)
          .to have_current_path(path)
      end

      def container
        find("bcf-new-split")
      end

      private

      def default?
        model_id.nil?
      end
    end
  end
end
