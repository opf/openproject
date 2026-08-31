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

module CustomStylesHelper
  include TabsHelper

  def pdf_tab?
    selected = selected_tab(design_tabs)
    selected && selected[:pdf]
  end

  def show_theme_selector?
    selected = selected_tab(design_tabs)
    selected && %w[interface branding].include?(selected[:name])
  end

  def default_colors_tab?
    selected_tab(design_tabs)&.dig(:name) == "default_colors"
  end

  def design_tabs
    [
      {
        name: "interface",
        partial: "custom_styles/interface",
        path: custom_style_path(tab: :interface),
        label: t(:"admin.custom_styles.tab_interface")
      },
      {
        name: "branding",
        partial: "custom_styles/branding",
        path: custom_style_path(tab: :branding),
        label: t(:"admin.custom_styles.tab_branding")
      },
      {
        name: "default_colors",
        partial: "custom_styles/default_colors",
        path: custom_style_path(tab: :default_colors),
        label: t(:"admin.custom_styles.tab_default_colors")
      },
      {
        name: "pdf_export_styles",
        partial: "custom_styles/pdf_export_styles",
        path: custom_style_path(tab: :pdf_export_styles),
        label: t(:"admin.custom_styles.tab_pdf_export_styles"),
        pdf: true
      },
      {
        name: "pdf_export_font",
        partial: "custom_styles/pdf_export_font",
        path: custom_style_path(tab: :pdf_export_font),
        label: t(:"admin.custom_styles.tab_pdf_export_font"),
        pdf: true
      }
    ]
  end

  def apply_custom_styles?(skip_ee_check: OpenProject::Configuration.bim?)
    # Apply custom styles either if EE allows OR we are on a BIM edition with the BIM theme active.
    CustomStyle.current.present? &&
      (EnterpriseToken.allows_to?(:define_custom_style) || skip_ee_check)
  end

  def custom_logo?
    desktop_logo_present?
  end

  def desktop_logo_present?
    style = CustomStyle.current
    return false unless style

    custom_logo_fields_present?(style, :desktop) || style.theme_logo.present?
  end

  def mobile_logo_present?
    style = CustomStyle.current
    return false unless style

    custom_logo_fields_present?(style, :mobile)
  end

  def custom_logo_url(custom_style, attachment)
    return if attachment.blank?

    custom_logo_source(custom_style, attachment.mounted_as, true)
  end

  def custom_logo_uploads(custom_style, mobile: false)
    logo_context = mobile ? :mobile : :desktop

    CustomStyle::LOGO_FIELDS.fetch(logo_context).map do |mode, field|
      custom_logo_upload(custom_style, mode:, field:, mobile:)
    end
  end

  def show_waffle_icon?
    # Both logos → show icon (mobile logo will be applied by CSS)
    return true if desktop_logo_present? && mobile_logo_present?

    # Only mobile → show icon
    return true if mobile_logo_present?

    # Only desktop → hide icon on mobile
    return false if desktop_logo_present?

    # No logos → show fallback icon
    true
  end

  # The default favicon and touch icons are both the same for normal OP and BIM.
  def apply_custom_favicon?
    apply_custom_styles?(skip_ee_check: false) && CustomStyle.current.favicon.present?
  end

  # The default favicon and touch icons are both the same for normal OP and BIM.
  def apply_custom_touch_icon?
    apply_custom_styles?(skip_ee_check: false) && CustomStyle.current.touch_icon.present?
  end

  def export_fonts_fields(custom_style)
    %i[regular bold italic bold_italic].map do |variant|
      field = :"export_font_#{variant}"
      font = custom_style.public_send(field)
      {
        field: field,
        label: I18n.t("label_custom_export_font_#{variant}"),
        present: font.present?,
        filename: custom_style.id && font.present? ? File.basename(font.file.path) : nil,
        delete_path: public_send(:"custom_style_export_font_#{variant}_delete_path"),
        instructions: I18n.t("text_custom_export_font_#{variant}_instructions")
      }
    end
  end

  private

  def custom_logo_fields_present?(custom_style, context)
    CustomStyle::LOGO_FIELDS.fetch(context).values.any? do |field|
      custom_style.public_send(field).present?
    end
  end

  def custom_logo_upload(custom_style, mode:, field:, mobile:)
    attachment = custom_style.public_send(field)
    present = custom_style.persisted? && attachment.present?

    {
      field:,
      label: t("admin.custom_styles.branding.modes.#{mode}.name"),
      present:,
      source: custom_logo_source(custom_style, field, present),
      img_class: mobile ? "custom-logo-mobile-preview" : "custom-logo-preview",
      accept: "image/*",
      delete_path: custom_logo_delete_path(field),
      instructions: t("admin.custom_styles.branding.modes.#{mode}.description")
    }
  end

  def custom_logo_source(custom_style, field, present)
    return unless present

    path_options = {
      digest: custom_style.digest,
      filename: custom_style.public_send(:"#{field}_identifier")
    }

    if field == :logo
      custom_style_logo_path(**path_options)
    elsif field == :logo_mobile
      custom_style_logo_mobile_path(**path_options)
    else
      custom_style_logo_variant_path(**path_options, variant: field)
    end
  end

  def custom_logo_delete_path(field)
    if field == :logo
      custom_style_logo_delete_path
    elsif field == :logo_mobile
      custom_style_logo_mobile_delete_path
    else
      custom_style_logo_variant_delete_path(variant: field)
    end
  end
end
