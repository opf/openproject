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
        label: t(:"admin.custom_styles.tab_pdf_export_styles")
      }
    ]
  end

  def apply_custom_styles?(skip_ee_check: OpenProject::Configuration.bim?)
    # Apply custom styles either if EE allows OR we are on a BIM edition with the BIM theme active.
    CustomStyle.current.present? &&
      (EnterpriseToken.allows_to?(:define_custom_style) || skip_ee_check)
  end

  # The default favicon and touch icons are both the same for normal OP and BIM.
  def apply_custom_favicon?
    apply_custom_styles?(skip_ee_check: false) && CustomStyle.current.favicon.present?
  end

  # The default favicon and touch icons are both the same for normal OP and BIM.
  def apply_custom_touch_icon?
    apply_custom_styles?(skip_ee_check: false) && CustomStyle.current.touch_icon.present?
  end
end
