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
    class BcfXmlSeeder < ::Seeder
      attr_reader :project, :project_data

      def initialize(project, project_data)
        super()
        @project = project
        @project_data = project_data
      end

      def seed_data!
        filename = project_data.lookup("bcf_xml_file")
        return if filename.blank?

        print_status "    ↳ Import BCF XML file"

        import_options = {
          invalid_people_action: "anonymize",
          unknown_mails_action: "anonymize",
          non_members_action: "anonymize"
        }

        bcf_xml_file = Rails.root.join("modules/bim/files", filename).to_s
        importer = ::OpenProject::Bim::BcfXml::Importer.new(bcf_xml_file, project, current_user: admin_user)
        importer.import!(import_options).flatten
      end
    end
  end
end
