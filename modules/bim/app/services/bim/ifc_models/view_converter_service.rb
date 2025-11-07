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

      # Enhanced: 6-stage pipeline with progress tracking
      CONVERSION_STAGES = [
        { name: :validation, weight: 5 },
        { name: :ifc_to_dae, weight: 20 },
        { name: :dae_to_gltf, weight: 20 },
        { name: :gltf_to_xkt, weight: 40 },
        { name: :enhanced_metadata, weight: 15 }
      ].freeze

      def initialize(ifc_model)
        @errors = ActiveModel::Errors.new(self)
        @ifc_model = ifc_model
        @current_progress = 0
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
        initialize_conversion_logs

        validate!

        Dir.mktmpdir do |dir|
          self.working_directory = dir

          # Enhanced: Execute pipeline with progress tracking
          execute_stages

          ifc_model.conversion_status = ::Bim::IfcModels::IfcModel.conversion_statuses[:completed]
          ifc_model.conversion_error_message = nil
          ifc_model.conversion_progress = 100

          ServiceResult.new(success: ifc_model.save, result: ifc_model)
        end
      rescue StandardError => e
        handle_conversion_failure(e)
        ServiceResult.failure.tap { |r| r.errors.add(:base, e.message) }
      ensure
        self.working_directory = nil
      end

      private

      # Enhanced: Execute all conversion stages with progress tracking
      def execute_stages
        # Stage 1: Validation (NEW)
        execute_stage(:validation) { stage_validation }

        # Stage 2-5: Existing conversion pipeline
        tmp_ifc_path = link_to_ifc_file

        dae_path = execute_stage(:ifc_to_dae) { convert_to_collada(tmp_ifc_path) }
        gltf_path = execute_stage(:dae_to_gltf) { convert_to_gltf(dae_path) }
        xkt_path = execute_stage(:gltf_to_xkt) { convert_to_xkt(gltf_path) }

        save_xkt(xkt_path)

        # Stage 6: Enhanced metadata extraction (NEW)
        execute_stage(:enhanced_metadata) { stage_enhanced_metadata }
      end

      def execute_stage(stage_name)
        stage_config = CONVERSION_STAGES.find { |s| s[:name] == stage_name }

        update_stage_status(stage_name, :started)
        log_stage_start(stage_name)

        result = yield

        advance_progress(stage_config[:weight])
        log_stage_success(stage_name)

        result
      rescue StandardError => e
        log_stage_error(stage_name, e)
        raise
      end

      # NEW: Validation stage using ValidatorService
      def stage_validation
        validator = ValidatorService.new(ifc_model_path.to_s)
        validation_result = validator.call

        unless validation_result[:valid]
          errors = validation_result[:schema_errors].join('; ')
          raise "IFC validation failed: #{errors}"
        end

        # Log warnings if present
        if validation_result[:warnings].any?
          validation_result[:warnings].each do |warning|
            log_warning(:validation, warning)
          end
        end

        true
      end

      # NEW: Enhanced metadata extraction stage
      def stage_enhanced_metadata
        extractor = MetadataExtractorService.new(ifc_model)
        result = extractor.call

        if result.failure?
          # Don't fail the whole conversion if metadata extraction fails
          # Just log a warning
          log_warning(:enhanced_metadata, "Metadata extraction failed: #{result.errors.join('; ')}")
        else
          log_stage_info(:enhanced_metadata, "Metadata extracted successfully")
        end

        true
      rescue StandardError => e
        # Metadata extraction failure should not stop conversion
        log_warning(:enhanced_metadata, "Metadata extraction error: #{e.message}")
        true
      end

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
          Open3.capture2e(
            "IfcConvert",
            "--use-element-guids",
            "--no-progress",
            "--verbose",
            "--threads",
            "4",
            ifc_filepath,
            target_file,
            "--exclude",
            "entities",
            "IfcOpeningElement",
            chdir: working_directory
          )
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

      # NEW: Progress tracking and logging helpers

      def initialize_conversion_logs
        ifc_model.update!(conversion_logs: [])
      end

      def update_stage_status(stage_name, status)
        ifc_model.update!(conversion_stage: stage_name.to_s)
      end

      def advance_progress(weight)
        @current_progress += weight
        ifc_model.update!(conversion_progress: @current_progress.to_i)
      end

      def handle_conversion_failure(error)
        OpenProject.logger.error("Failed to convert IFC to XKT", exception: error)

        ifc_model.conversion_status = ::Bim::IfcModels::IfcModel.conversion_statuses[:error]
        ifc_model.conversion_error_message = error.message
        ifc_model.save
      end

      # Logging methods

      def log_stage_start(stage)
        add_log_entry(
          stage: stage.to_s,
          level: 'info',
          message: "Starting #{stage.to_s.humanize}",
          details: { started_at: Time.current.iso8601 }
        )
      end

      def log_stage_success(stage)
        add_log_entry(
          stage: stage.to_s,
          level: 'info',
          message: "Completed #{stage.to_s.humanize}",
          details: { completed_at: Time.current.iso8601 }
        )
      end

      def log_stage_error(stage, error)
        add_log_entry(
          stage: stage.to_s,
          level: 'error',
          message: "Failed #{stage.to_s.humanize}: #{error.message}",
          details: {
            error_class: error.class.name,
            backtrace: error.backtrace&.first(5)
          }
        )
      end

      def log_warning(stage, message)
        add_log_entry(
          stage: stage.to_s,
          level: 'warning',
          message: message,
          details: {}
        )
      end

      def log_stage_info(stage, message)
        add_log_entry(
          stage: stage.to_s,
          level: 'info',
          message: message,
          details: {}
        )
      end

      def add_log_entry(log_data)
        logs = ifc_model.conversion_logs || []
        logs << log_data.merge(timestamp: Time.current.iso8601)
        ifc_model.update!(conversion_logs: logs)
      end
    end
  end
end
