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
module Bim
  module DemoData
    class IfcModelSeeder < ::Seeder
      attr_reader :project, :project_data

      def initialize(project, project_data)
        super()
        @project = project
        @project_data = project_data
      end

      def seed_data!
        models = project_data.lookup("ifc_models")
        return if models.blank?

        print_status "    ↳ Import IFC Models"

        models.each do |model|
          seed_model model
        end
      end

      private

      def seed_model(model)
        xkt_data = get_xkt_file(model["file"])

        if xkt_data.nil?
          print_status "\n    ↳ Missing converted data for ifc model"
        else
          create_model(model, admin_user, xkt_data)
        end
      end

      def create_model(model, user, xkt_data)
        model_container = create_model_container project, user, model["name"], model["default"]

        add_ifc_model_attachment model_container, user, xkt_data, "xkt"
      end

      def create_model_container(project, user, title, default)
        model_container = Bim::IfcModels::IfcModel.new
        model_container.title = title
        model_container.project = project
        model_container.uploader = user
        model_container.is_default = default

        model_container.save!
        model_container
      end

      def add_ifc_model_attachment(model_container, user, file, description)
        attachment = Attachment.new(
          container: model_container,
          author: user,
          file:,
          description:
        )
        attachment.save!
      end

      def get_xkt_file(name)
        xkt_path = OpenProject::Bim::Engine.root.join("files/ifc_models", name, "#{name}.xkt")
        return unless xkt_path.exist?

        File.new(xkt_path)
      end
    end
  end
end
