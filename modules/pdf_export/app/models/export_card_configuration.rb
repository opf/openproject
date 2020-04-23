#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
#++


class ExportCardConfiguration < ApplicationRecord

  class RowsYamlValidator < ActiveModel::Validator
    REQUIRED_GROUP_KEYS = ["rows"]
    VALID_GROUP_KEYS = ["rows", "has_border", "height"]
    REQUIRED_ROW_KEYS = ["columns"]
    VALID_ROW_KEYS = ["columns", "height", "priority"]
    # TODO: Security Consideration
    # Should we define which model properties are visible and if so how?
    # VALID_MODEL_PROPERTIES = [""]
    REQUIRED_COLUMN_KEYS = []
    VALID_COLUMN_KEYS = ["has_label", "min_font_size", "max_font_size",
      "font_size", "font_style", "text_align", "minimum_lines", "render_if_empty",
      "width", "indented", "custom_label", "has_count"]
    NUMERIC_COLUMN_VALUE = ["min_font_size", "max_font_size", "font_size", "minimum_lines"]

    def raise_yaml_error
      raise ArgumentError, I18n.t('validation_error_yaml_is_badly_formed')
    end

    def assert_required_keys(hash, valid_keys, required_keys)
      raise_yaml_error if !hash.is_a?(Hash)

      begin
        hash.assert_valid_keys valid_keys
      rescue ArgumentError => e
        # Small hack alert: Catch a raise error again but with localised text
        raise ArgumentError, "#{I18n.t('validation_error_uknown_key')} '#{e.message.split(": ")[1]}'"
      end

      pending_keys = required_keys - hash.keys
      raise(ArgumentError, "#{I18n.t('validation_error_required_keys_not_present')} #{pending_keys.join(", ")}") unless pending_keys.empty?
    end

    def check_valid_value_type(value, type)
      raise(ArgumentError, "#{I18n.t('validation_error_yaml_is_badly_formed')}") unless value.is_a?type
    end

    def validate(record)
      begin
        if record.rows.nil? || !(YAML::load(record.rows)).is_a?(Hash)
          record.errors[:rows] << I18n.t('validation_error_yaml_is_badly_formed')
          return false
        end
      rescue Psych::SyntaxError => e
        record.errors[:rows] << I18n.t('validation_error_yaml_is_badly_formed')
          return false
      end

      begin
        groups = YAML::load(record.rows)
        groups.each do |gk, gv|
          assert_required_keys(gv, VALID_GROUP_KEYS, REQUIRED_GROUP_KEYS)
          raise_yaml_error if !gv["rows"].is_a?(Hash)
          gv["rows"].each do |rk, rv|
            assert_required_keys(rv, VALID_ROW_KEYS, REQUIRED_ROW_KEYS)
            raise_yaml_error if !rv["columns"].is_a?(Hash)
            rv["columns"].each do |ck, cv|
              assert_required_keys(cv, VALID_COLUMN_KEYS, REQUIRED_COLUMN_KEYS)
              cv.map{|cname, cvalue | check_valid_value_type(cvalue, Numeric) if NUMERIC_COLUMN_VALUE.include?(cname)}
            end
          end
        end
      rescue ArgumentError => e
        record.errors[:rows] << "#{I18n.t('yaml_error')} #{e.message}"
      end
    end
  end

  include OpenProject::PDFExport::Exceptions

  validates :name, presence: true
  validates :rows, rows_yaml: true
  validates :per_page, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :page_size, inclusion: { in: %w(A4) }, allow_nil: false
  validates :orientation, inclusion: { in: %w(landscape portrait) }, allow_nil: true

  scope :active, -> { where(active: true) }

  def self.default
    ExportCardConfiguration.active.select { |c| c.is_default? }.first || ExportCardConfiguration.active.first
  end

  def activate
    self.update!({active: true})
  end

  def deactivate
    if !self.is_default?
      self.update!({active: false})
    else
      false
    end
  end

  def landscape?
    !portrait?
  end

  def portrait?
    orientation == "portrait"
  end

  def rows_hash
    config = YAML::load(rows)
    raise BadlyFormedExportCardConfigurationError.new(I18n.t('validation_error_yaml_is_badly_formed')) if !config.is_a?(Hash)
    config
  end

  def is_default?
    self.name.downcase == "default"
  end

  def can_delete?
    !self.is_default?
  end

  def can_activate?
    !self.active
  end

  def can_deactivate?
    self.active && !is_default?
  end
end
