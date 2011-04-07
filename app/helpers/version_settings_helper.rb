module VersionSettingsHelper
  unloadable

  def version_settings_fields(form, version)
    version.build_version_setting(:display => VersionSetting::DISPLAY_LEFT) if version.version_setting.nil?

  	form.fields_for :version_setting do |sf|
		  return "<p>#{sf.select :display, position_display_options}</p>"
    end
  end

  private

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