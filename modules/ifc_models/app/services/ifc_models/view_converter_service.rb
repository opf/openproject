#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
#+
require 'open3'

module IFCModels
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
      @@available ||= begin
        PIPELINE_COMMANDS.select do |command|
          _, status = Open3.capture2e('which', command)
          status.exitstatus == 0
        end
      end
    end

    def call
      validate!

      Dir.mktmpdir do |dir|
        perform_conversion!(dir)
        if ifc_model.save
          ServiceResult.new(success: true, result: ifc_model)
        else
          ServiceResult.new(success: false, errors: ifc_model.errors)
        end
      end
    rescue StandardError => e
      OpenProject.logger.error("Failed to convert IFC to XKT", exception: e)
      ServiceResult.new(success: false).tap { |r| r.errors.add(:base, e.message) }
    end

    def perform_conversion!(dir)
      # Step 1: IfcConvert
      Rails.logger.debug { "Converting #{ifc_model.inspect} to DAE"}
      ifc_file = ifc_model.ifc_attachment.diskfile.path
      collada_file = convert_to_collada(ifc_file, dir)

      # Step 2: Collada2GLTF
      Rails.logger.debug { "Converting #{ifc_model.inspect} to GLTF"}
      gltf_file = convert_to_gltf(collada_file, dir)

      # Step 3: Convert to XKT
      Rails.logger.debug { "Converting #{ifc_model.inspect} to XKT"}
      xkt_file = convert_to_xkt(gltf_file, dir)
      ifc_model.xkt_attachment = File.new xkt_file

      # Convert metadata
      Rails.logger.debug { "Retrieving metadata of #{ifc_model.inspect}"}
      metadata_file = convert_metadata(ifc_file, dir)
      ifc_model.metadata_attachment = File.new metadata_file
    end

    ##
    # Call IfcConvert with an IFC file to output an identically-named
    # DAE collada file.
    #
    # @param ifc_filepath {String} Path to the IFC model file
    # @param target_dir {String} Path to the temporary output folder
    def convert_to_collada(ifc_filepath, target_dir)
      convert!(ifc_filepath, target_dir, 'dae') do |target_file|
        Open3.capture2e('IfcConvert', '--use-element-guids', ifc_filepath, target_file)
      end
    end

    ##
    # Call COLLADA2GLTF with the converted DAE file.
    #
    # @param dae_filepath {String} Path to the converted DAE model file
    # @param target_dir {String} Path to the temporary output folder
    def convert_to_gltf(dae_filepath, target_dir)
      convert!(dae_filepath, target_dir, 'gltf') do |target_file|
        Open3.capture2e('COLLADA2GLTF', '-i', dae_filepath, '-o', target_file)
      end
    end

    ##
    # Call gltf2xkt with the converted gltf file.
    #
    # @param gltf_filepath {String} Path to the converted GLTF model file
    # @param target_dir {String} Path to the temporary output folder
    def convert_to_xkt(gltf_filepath, target_dir)
      convert!(gltf_filepath, target_dir, 'xkt') do |target_file|
        Open3.capture2e('gltf2xkt', '-s', gltf_filepath, '-o', target_file)
      end
    end

    ##
    # Call xeokit-metadata
    #
    # @param ifc_filepath {String} Path to the converted IFC model file
    # @param target_dir {String} Path to the temporary output folder
    def convert_metadata(ifc_filepath, target_dir)
      convert!(ifc_filepath, target_dir, 'json') do |target_file|
        Open3.capture2e('xeokit-metadata', ifc_filepath, target_file)
      end
    end

    ##
    # Build input filename and target filename
    def convert!(source_file, target_dir, ext, &block)
      filename = File.basename(source_file, '.*')
      target_filename = "#{filename}.#{ext}"
      target_file = File.join(target_dir, target_filename)

      out, status = block.call target_file

      if status.exitstatus != 0
        raise "Failed to convert #{filename} to #{ext}: #{out}"
      end

      target_file
    end

    def validate!
      unless self.class.available?
        missing = PIPELINE_COMMANDS - self.class.available_commands
        raise I18n.t('ifc_models.conversion.missing_commands', names: missing.join(", "))
      end

      true
    end
  end
end
