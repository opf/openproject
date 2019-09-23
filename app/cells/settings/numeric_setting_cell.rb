module Settings
  ##
  # A text field to enter numeric values.
  class NumericSettingCell < ::RailsCell
    include SettingsHelper

    options :unit, :title
    options size: 3

    def name # name of setting and tag
      model
    end
  end
end
