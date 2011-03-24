module VersionSettingsHelper
  unloadable

  def position_display_options
    options = [::VersionSetting::DISPLAY_NONE,
               ::VersionSetting::DISPLAY_LEFT,
               ::VersionSetting::DISPLAY_RIGHT]
    options.collect {|s| [humanize_display_option(s), s]}
  end

  private

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