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
    CustomStyle.current.present? &&
      (CustomStyle.current.logo.present? || CustomStyle.current.theme_logo.present?)
  end

  def desktop_logo_present?
    style = CustomStyle.current
    return false unless style

    style.logo.present? || style.theme_logo.present?
  end

  def mobile_logo_present?
    style = CustomStyle.current
    return false unless style

    style.logo_mobile.present?
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
end
