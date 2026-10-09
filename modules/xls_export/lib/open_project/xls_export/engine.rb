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

module OpenProject::XlsExport
  class Engine < ::Rails::Engine
    engine_name :openproject_xls_export

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-xls_export",
             author_url: "https://www.openproject.org",
             bundled: true

    config.to_prepare do
      OpenProject::XlsExport::Hooks::WorkPackageHook
    end

    initializer "xls_export.register_mimetypes" do
      next if defined? Mime::XLS

      Mime::Type.register("application/vnd.ms-excel",
                          :xls,
                          %w(application/vnd.ms-excel))
    end

    class_inflection_override("xls" => "XLS")

    config.to_prepare do
      ::Exports::Register.register do
        list(::WorkPackage, XlsExport::WorkPackage::Exporter::XLS)
        list(::Project, XlsExport::Project::Exporter::XLS)
      end
    end
  end
end
