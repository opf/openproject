module VersionSettingsHelper
  unloadable

  def version_settings_fields(version, project)
    setting = version_setting_for_project(version, project)

    ret = "<p>"
    ret += label_tag name_for_setting_attributes("display"), l(:field_display)
    ret += select_tag name_for_setting_attributes("display"), options_for_select(position_display_options, setting.display)
    ret += hidden_field_tag name_for_setting_attributes("project_id"), project.id
    ret += hidden_field_tag name_for_setting_attributes("id"), setting.id
    ret += "</p>"

    ret
  end

  private

  def version_setting_for_project(version, project)
    setting = version.version_settings.detect { |vs| vs.project_id == project.id || vs.project_id.nil? } if version.version_settings.present?
    #nil? because some settings in the active codebase do have that right now
    debugger
    setting = VersionSetting.new(:display => VersionSetting::DISPLAY_LEFT, :project => project) if setting.nil?

    setting
  end

  def name_for_setting_attributes(attribute)
    "version[version_settings_attributes][][#{attribute}]"
  end

  def position_display_options
    options = [::VersionSetting::DISPLAY_NONE,
               ::VersionSetting::DISPLAY_LEFT,
               ::VersionSetting::DISPLAY_RIGHT]
    options.collect {|s| [humanize_display_option(s), s]}
  end

  def humanize_display_option(option)
    case option
      when ::VersionSetting::DISPLAY_NONE
        t("version_settings_display_option_none")
      when ::VersionSetting::DISPLAY_LEFT
        t("version_settings_display_option_left")
      when ::VersionSetting::DISPLAY_RIGHT
        t("version_settings_display_option_right")
    end
  end
end