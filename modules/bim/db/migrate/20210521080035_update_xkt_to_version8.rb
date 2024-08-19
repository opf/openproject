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

class UpdateXktToVersion8 < ActiveRecord::Migration[6.1]
  SEEDED_MODEL_DATA = { "Hospital - Architecture (cc-by-sa-3.0 Autodesk Inc.)" => "hospital_architecture",
                        "Hospital - Structural (cc-by-sa-3.0 Autodesk Inc.)" => "hospital_structural",
                        "Hospital - Mechanical (cc-by-sa-3.0 Autodesk Inc.)" => "hospital_mechanical" }.freeze

  # Note: rails 7.1 breaks the class' ancestor chain, and raises an error, when a class
  # with an enum definition without a database field is being referenced.
  # Re-defining the IfcModel class without the enum to avoid the issue.
  class IfcModel < ApplicationRecord
    has_many :attachments, -> { where(container_type: "Bim::IfcModels::IfcModel") },
             foreign_key: :container_id,
             class_name: "Attachment"
  end

  def up
    # Queue every IFC model for a new transformation.
    Rails.logger.info "Migrate all IFC models to the latest XKT version"

    if IfcModel.count.zero?
      Rails.logger.info("No IFC models to migrate")
      return
    end

    # Only report an error if you really need the IFC models to be converted. If the BIM edition is not active then
    # you don't need the IFC models to get converted and even more important, you don't need the full conversion
    # pipeline to be installed.
    unless ::OpenProject::Configuration.bim? && ::Bim::IfcModels::ViewConverterService.available?
      Rails.logger.error("Cannot convert IFC models. Some or all IFC conversion tools are not installed on your server.")
      return
    end

    migrate_all_ifc_models
    update_demo_xkt_models
  end

  def down
    # This migration is irreversible
  end

  private

  def migrate_all_ifc_models
    IfcModel.find_each do |ifc_model|
      cleanup_metadata_attachment(ifc_model)
      # We have seeded models that do not have an IFC attachment. They cannot get converted as an IFC file is
      # necessary.
      next if ifc_model.attachments.find_by(description: "ifc").nil?

      ::Bim::IfcModels::IfcConversionJob.perform_later(ifc_model)
    end
  end

  def cleanup_metadata_attachment(ifc_model)
    ifc_model.attachments.find_by(description: "metadata")&.destroy
  end

  def update_demo_xkt_models
    project = Project.find_by(identifier: "demo-bcf-management-project")
    return unless project

    ifc_models = project.ifc_models.joins(:attachments)
                        .where("attachments.description LIKE 'xkt' AND ifc_models.title IN (?)",
                               SEEDED_MODEL_DATA.keys)

    ifc_models.each do |ifc_model|
      old_attachment = ifc_model.xkt_attachment
      next unless old_attachment

      attachment = Attachment.new(
        container: ifc_model,
        author: old_attachment.author,
        file: get_file(SEEDED_MODEL_DATA[ifc_model.title]),
        description: old_attachment.description
      )

      old_attachment.destroy
      attachment.save! validate: false
    end
  end

  def get_file(name)
    path = "modules/bim/files/ifc_models/#{name}/"
    file_name = "#{name}.xkt"
    return unless File.exist?(path + file_name)

    File.new(Rails.root.join(path, file_name))
  end
end
