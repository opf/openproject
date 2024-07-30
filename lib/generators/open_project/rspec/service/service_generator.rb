# frozen_string_literal: true

# -- copyright
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
# ++

module OpenProject
  module Rspec
    module Generators
      class ServiceGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        argument :service_name,
                 type: :string,
                 required: true,
                 desc: "Constant of the service the spec is being generated for"

        class_option :module_name,
                     aliases: %i[m],
                     type: :string,
                     optional: true,
                     desc: "Module to generate the service spec file for"

        def generate_service_spec
          template "service_spec.rb", file_path
        end

        private

        def file_path
          namespace = service_name.deconstantize.underscore
          file_name = "#{service_name.demodulize.underscore}_spec.rb"

          Rails.root.join(service_specs_root_directory,
                          namespace,
                          file_name)
        end

        def service_specs_root_directory
          if options[:module_name]
            "modules/#{options[:module_name]}/spec/services"
          else
            "spec/services"
          end
        end
      end
    end
  end
end
