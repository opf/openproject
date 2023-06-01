#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class PdfExportConfiguration < ApplicationRecord
  class PdfExportYamlValidator < ActiveModel::Validator
    include WorkPackage::PDFExport::Style

    def validate_yml(record)
      if record.styles.nil? || !YAML::load(record.styles).is_a?(Hash)
        record.errors.add(:styles, I18n.t('pdf_export.settings.yaml_is_badly_formed'))
        return false
      end
      true
    rescue Psych::SyntaxError => e
      record.errors.add(:styles, I18n.t('pdf_export.settings.yaml_is_badly_formed'))
      false
    end

    def validate_styles(record)
      config = YAML::load(record.styles).deep_symbolize_keys
      validate_styles_yml(config)
      true
    rescue StyleValidationError => e
      record.errors.add(:styles, "#{I18n.t('pdf_export.settings.yaml_error')} #{e.message}")
      false
    end

    def validate(record)
      validate_yml(record) && validate_styles(record)
    end
  end

  include OpenProject::PDFExport::Exceptions

  validates :name, presence: true
  validates :styles, pdf_export_yaml: true

  scope :active, -> { where(active: true) }

  self.table_name = "pdf_export_configurations"

  def self.default
    PdfExportConfiguration.active.select { |c| c.is_default? }.first || PdfExportConfiguration.active.first
  end

  def activate
    update!({ active: true })
  end

  def deactivate
    if is_default?
      false
    else
      update!({ active: false })
    end
  end

  def styles_hash
    config = YAML::load(styles)
    raise BadlyFormedExportCardConfigurationError.new(I18n.t('pdf_export.settings.yaml_is_badly_formed')) if !config.is_a?(Hash)

    config
  end

  def is_default?
    name.downcase == "default"
  end

  def can_delete?
    !is_default?
  end

  def can_activate?
    !active
  end

  def can_deactivate?
    active && !is_default?
  end
end
