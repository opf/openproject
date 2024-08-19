#-- copyright
# OpenProject is a project management system.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# +
require "open3"

module Bim
  module IfcModels
    class ViewConverterService
      attr_reader :ifc_model, :errors

      PIPELINE_COMMANDS ||= %w[IfcConvert COLLADA2GLTF gltf2xkt xeokit-metadata].freeze

      def initialize(ifc_model)
        @errors = ActiveModel::Errors.new(self)
        @ifc_model = ifc_model
      end

      ##
      # Check availability of the pipeline
      def self.available?
        available_commands.length == PIPELINE_COMMANDS.length
      end

      def self.available_commands
        @available_commands ||= PIPELINE_COMMANDS.select do |command|
          _, status = Open3.capture2e("which", command)
          status.exitstatus.zero?
        end
      end

      def call
        ifc_model.processing!

        validate!

        Dir.mktmpdir do |dir|
          self.working_directory = dir

          perform_conversion!

          ifc_model.conversion_status = ::Bim::IfcModels::IfcModel.conversion_statuses[:completed]
          ifc_model.conversion_error_message = nil

          ServiceResult.new(success: ifc_model.save, result: ifc_model)
        end
      rescue StandardError => e
        OpenProject.logger.error("Failed to convert IFC to XKT", exception: e)

        ifc_model.conversion_status = ::Bim::IfcModels::IfcModel.conversion_statuses[:error]
        ifc_model.conversion_error_message = e.message
        ifc_model.save

        ServiceResult.failure.tap { |r| r.errors.add(:base, e.message) }
      ensure
        self.working_directory = nil
      end

      private

      def perform_conversion!
        # Step 0: avoid file name issues (e.g. umlauts) in the pipeline
        tmp_ifc_path = link_to_ifc_file

        tmp_ifc_path
          .then { |ifc_path| convert_to_collada ifc_path } # Step 1: IfcConvert
          .then { |collada_path| convert_to_gltf collada_path } # Step 2: Collada2GLTF
          .then { |gltf_path| convert_to_xkt gltf_path } # Step 3: Create XKT from extracted metadata JSON and GLTF
          .then { |xkt_path| save_xkt xkt_path }
      end

      def link_to_ifc_file
        return @tmp_ifc_path if @tmp_ifc_path

        @tmp_ifc_path = File.join working_directory, "model.ifc"

        FileUtils.symlink ifc_model_path.to_s, @tmp_ifc_path

        @tmp_ifc_path
      end

      def ifc_model_path
        Pathname(ifc_model.ifc_attachment.diskfile.path)
      end

      def save_xkt(xkt_path)
        final_xkt_path = change_basename xkt_path, ifc_model_path, ".xkt"

        # If the original file is already called 'model.ifc' then renaming the file is
        # unnecessary as the conversion result is already called model.xkt then.
        # Hence only rename if `xkt_path` is actually different from `final_xkt_path`.
        FileUtils.mv xkt_path, final_xkt_path.to_s unless xkt_path.to_s == final_xkt_path.to_s

        ifc_model.xkt_attachment = File.new final_xkt_path.to_s
      end

      ##
      # Call IfcConvert with an IFC file to output an identically-named
      # DAE collada file.
      #
      # @param ifc_filepath {String} Path to the IFC model file
      def convert_to_collada(ifc_filepath)
        Rails.logger.debug { "Converting #{ifc_model.inspect} to DAE" }

        convert!(ifc_filepath, "dae") do |target_file|
          # To include IfcSpace entities, which by default are excluded by
          # IfcConvert, together with IfcOpeningElement, we need to over-
          # write the default exclude parameter to only exclude
          # IfcOpeningElements.
          # https://github.com/IfcOpenShell/IfcOpenShell/wiki#ifconvert
          Open3.capture2e("IfcConvert",
                          "--use-element-guids",
                          "--no-progress",
                          "--verbose",
                          "--threads",
                          "4",
                          ifc_filepath,
                          target_file,
                          "--exclude",
                          "entities",
                          "IfcOpeningElement")
        end
      end

      ##
      # Call COLLADA2GLTF with the converted DAE file.
      #
      # @param dae_filepath {String} Path to the converted DAE model file
      def convert_to_gltf(dae_filepath)
        Rails.logger.debug { "Converting #{ifc_model.inspect} to GLTF" }

        convert!(dae_filepath, "gltf") do |target_file|
          Open3.capture2e("COLLADA2GLTF", "--materialsCommon", "-i", dae_filepath, "-o", target_file)
        end
      end

      ##
      # Call gltf2xkt with the converted gltf file.
      #
      # @param gltf_filepath {String} Path to the converted GLTF model file
      def convert_to_xkt(gltf_filepath)
        Rails.logger.debug { "Converting #{ifc_model.inspect} to XKT" }

        metadata_file = convert_metadata(link_to_ifc_file)

        convert!(gltf_filepath, "xkt") do |target_file|
          Open3.capture2e("gltf2xkt", "-s", gltf_filepath, "-m", metadata_file, "-o", target_file)
        end
      end

      ##
      # Call xeokit-metadata
      #
      # @param ifc_filepath {String} Path to the converted IFC model file
      def convert_metadata(ifc_filepath)
        Rails.logger.debug { "Retrieving metadata of #{ifc_model.inspect}" }

        convert!(ifc_filepath, "json") do |target_file|
          Open3.capture2e("xeokit-metadata", ifc_filepath, target_file)
        end
      end

      ##
      # Build input filename and target filename
      def convert!(source_file, ext)
        raise ArgumentError, "missing working directory" unless working_directory.present?

        filename = File.basename(source_file, ".*")
        target_filename = "#{filename}.#{ext}"
        target_file = File.join(working_directory, target_filename)

        out, status = yield target_file

        if status.exitstatus != 0
          raise "Failed to convert #{filename} to #{ext}: #{out}"
        end

        target_file
      end

      def validate!
        unless self.class.available?
          missing = PIPELINE_COMMANDS - self.class.available_commands
          raise I18n.t("ifc_models.conversion.missing_commands", names: missing.join(", "))
        end

        true
      end

      def change_basename(from, to, ext)
        to = Pathname(to)

        Pathname(from).parent.join(to.basename.to_s.sub(to.extname, ext))
      end

      def working_directory=(dir)
        @working_directory = dir
      end

      def working_directory
        @working_directory
      end
    end
  end
end
