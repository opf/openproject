require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VersionSettingsHelper do
  describe :position_display_options do
    before(:each) do
      @expected_options = [[I18n.t("version_settings_display_option_none"), 1],
                          [I18n.t("version_settings_display_option_left"), 2],
                          [I18n.t("version_settings_display_option_right"), 3]]
    end

    it { helper.position_display_options.should eql @expected_options }
  end
end