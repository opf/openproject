module Settings
  ##
  # A text field to enter numeric values.
  class NumericSettingCell < ::RailsCell
    include SettingsHelper

    options :unit, :title
    options size: 3

    # name of setting and tag
    def name
      model
    end
  end
end
