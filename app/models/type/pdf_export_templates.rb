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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Type::PdfExportTemplates
  include WorkPackage::PDFExport::Templates

  Template = Data.define(:id, :label, :caption, :enabled, :settings_component)

  class ReadonlyError < StandardError; end

  def initialize(type)
    @type = type
  end

  def readonly?
    OpenProject::FeatureDecisions.type_variants_active? && @type.linked?(TypeVariant::PDF_EXPORT)
  end

  def list
    templates = build_templates
    order = @type.export_templates_order || []
    return templates if order.empty?

    sort_by_order(templates, order)
  end

  def list_enabled
    list.filter(&:enabled)
  end

  def find(template_id)
    built_in_template = built_in_templates.find { |t| t[:id] == template_id }
    to_template(built_in_template, @type.export_templates_disabled || []) if built_in_template
  end

  def enable_all
    raise_if_readonly!

    @type.export_templates_disabled = []
  end

  def disable_all
    raise_if_readonly!

    @type.export_templates_disabled = built_in_templates.pluck(:id)
  end

  def toggle(template_id)
    raise_if_readonly!

    disabled = @type.export_templates_disabled || []
    if disabled.include?(template_id)
      disabled.delete(template_id)
    else
      disabled.push(template_id)
    end
    @type.export_templates_disabled = disabled
  end

  def move(template_id, position)
    raise_if_readonly!

    ordered_template_ids = list.map(&:id)
    prev_index = ordered_template_ids.find_index(template_id)
    ordered_template_ids.delete_at(prev_index) unless prev_index.nil?
    ordered_template_ids.insert(position, template_id)
    @type.export_templates_order = ordered_template_ids
  end

  def settings_for(template_id)
    validate_template_id!(template_id)

    (@type.export_templates_settings || {}).fetch(template_id, {}).symbolize_keys
  end

  def update_settings(template_id, settings_hash)
    validate_template_id!(template_id)
    raise_if_readonly!

    all_settings = (@type.export_templates_settings || {}).dup
    all_settings[template_id] = (all_settings[template_id] || {}).merge(settings_hash.stringify_keys)
    @type.export_templates_settings = all_settings
  end

  def clear_setting(template_id, field)
    validate_template_id!(template_id)
    raise_if_readonly!

    all_settings = (@type.export_templates_settings || {}).dup
    return if all_settings[template_id].blank?

    all_settings[template_id] = all_settings[template_id].except(field.to_s)
    @type.export_templates_settings = all_settings
  end

  private

  def raise_if_readonly!
    raise ReadonlyError, "cannot modify PDF export template configuration while linked to a source type" if readonly?
  end

  def validate_template_id!(template_id)
    return if built_in_templates.any? { |t| t[:id] == template_id }

    raise ArgumentError, "Unknown PDF export template #{template_id.inspect}"
  end

  def build_templates
    disabled = @type.export_templates_disabled || []
    built_in_templates.map { |built_in_template| to_template(built_in_template, disabled) }
  end

  def to_template(built_in_template, disabled)
    Template.new(**built_in_template, enabled: disabled.exclude?(built_in_template[:id]))
  end

  def sort_by_order(templates, order)
    indexes = order.each_with_index.to_a.to_h
    templates.sort_by { |template| indexes[template.id] || templates.length }
  end
end
