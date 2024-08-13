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

require "bundler"
require "fileutils"

module ::OpenProject::Plugins
  module FrontendLinking
    class Generator
      attr_reader :openproject_plugins

      def initialize
        op_dep = load_known_opf_plugins

        @openproject_plugins = Bundler.load.specs.each_with_object({}) do |spec, h|
          if op_dep.include?(spec.name)
            h[spec.name] = spec.full_gem_path
          end
        end
      end

      ##
      # Register plugins with an Angular frontend to the CLI build.
      # For that, search all gems with the group :opf_plugins
      def regenerate!
        # Create links from plugins angular mdoules to frontend/src
        regenerate_angular_links
      end

      private

      ##
      # Register plugins with an Angular frontend to the CLI build.
      # For that, search all gems with the group :opf_plugins
      def regenerate_angular_links
        all_frontend_plugins.tap do |plugins|
          target_dir = Rails.root.join("frontend/src/app/features/plugins/linked")
          puts "Cleaning linked target directory #{target_dir}"

          # Removing the current linked directory and recreate
          FileUtils.remove_dir(target_dir, force: true)
          FileUtils.mkdir_p(target_dir)

          plugins.each do |name, path|
            source = File.join(path, "frontend", "module")
            target = File.join(target_dir, name)

            puts "Linking frontend of OpenProject plugin #{name} to #{target}."
            FileUtils.ln_sf(source, target)
          end

          generate_plugin_module(all_angular_frontend_plugins)
          generate_plugin_sass(all_plugins_with_global_styles)
        end
      end

      def all_frontend_plugins
        openproject_plugins.select do |_, path|
          frontend_entry = File.join(path, "frontend", "module")
          File.directory? frontend_entry
        end
      end

      def all_angular_frontend_plugins
        openproject_plugins.select do |_, path|
          frontend_entry = File.join(path, "frontend", "module", "main.ts")
          File.readable? frontend_entry
        end
      end

      def all_plugins_with_global_styles
        openproject_plugins.select do |_, path|
          style_file = File.join(path, "frontend", "module", "global_styles.*")
          !Dir.glob(style_file).empty?
        end
      end

      ##
      # Regenerate the frontend plugin module orchestrating the linked frontends
      def generate_plugin_module(plugins)
        file_register = Rails.root.join("frontend/src/app/features/plugins/linked-plugins.module.ts")
        template_file = File.read(File.expand_path("linked-plugins.module.ts.erb", __dir__))
        template = ::ERB.new template_file, trim_mode: "-"

        puts "Regenerating frontend plugin registry #{file_register}."
        context = ::OpenProject::Plugins::FrontendLinking::ErbContext.new plugins
        result = template.result(context.get_binding)
        File.write(file_register, result)
      end

      ##
      # Regenerate the frontend plugin sass files
      def generate_plugin_sass(plugins)
        file_register = Rails.root.join("frontend/src/app/features/plugins/linked-plugins.styles.sass")
        template_file = File.read(File.expand_path("linked-plugins.styles.sass.erb", __dir__))
        template = ::ERB.new template_file, trim_mode: "-"

        puts "Regenerating frontend plugin sass #{file_register}."
        context = ::OpenProject::Plugins::FrontendLinking::ErbContext.new plugins
        result = template.result(context.get_binding)
        File.write(file_register, result)
      end

      ##
      # Print all gemspecs of registered OP plugins
      # from the :opf_plugins group.
      def load_known_opf_plugins
        bundler_groups = %i[opf_plugins]
        gemfile_path = Rails.root.join("Gemfile")

        gems = Bundler::Dsl.evaluate(gemfile_path, "_temp_lockfile", true)

        gems.dependencies
          .each_with_object({}) do |dep, l|
          l[dep.name] = dep if (bundler_groups & dep.groups).any?
        end
          .compact
      end
    end
  end
end
