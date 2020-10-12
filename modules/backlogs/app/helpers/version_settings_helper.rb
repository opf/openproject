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

module VersionSettingsHelper
  def version_settings_fields(version, project)
    setting = version_setting_for_project(version, project)

    content_tag :div, class: 'form--field' do
      [
        styled_label_tag(name_for_setting_attributes('display'), t(:label_column_in_backlog)),
        content_tag(:div,
                    styled_select_tag(name_for_setting_attributes('display'), options_for_select(position_display_options, setting.display), container_class: '-xslim' ),
                    class: 'form--field-container'),
        version_hidden_id_field(setting),
        hidden_field_tag('project_id', project.id)
      ].join.html_safe
    end
  end

  private

  def version_hidden_id_field(setting)
    return '' unless setting.id

    hidden_field_tag(name_for_setting_attributes('id'), setting.id)
  end

  def version_setting_for_project(version, project)
    setting = version.version_settings.detect { |vs| vs.project_id == project.id || vs.project_id.nil? }

    # nil? because some settings in the active codebase do have that right now
    setting ||= version.version_settings.new(display: VersionSetting::DISPLAY_LEFT, project: project)

    setting
  end

  def name_for_setting_attributes(attribute)
    "version[version_settings_attributes][][#{attribute}]"
  end

  def position_display_options
    options = [::VersionSetting::DISPLAY_NONE,
               ::VersionSetting::DISPLAY_LEFT,
               ::VersionSetting::DISPLAY_RIGHT]
    options.map { |s| [humanize_display_option(s), s] }
  end

  def humanize_display_option(option)
    case option
    when ::VersionSetting::DISPLAY_NONE
      t('version_settings_display_option_none')
    when ::VersionSetting::DISPLAY_LEFT
      t('version_settings_display_option_left')
    when ::VersionSetting::DISPLAY_RIGHT
      t('version_settings_display_option_right')
    end
  end
end
