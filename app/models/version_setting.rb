class VersionSetting < ActiveRecord::Base
  belongs_to :project
  belongs_to :version

  DISPLAY_NONE = 1
  DISPLAY_LEFT = 2
  DISPLAY_RIGHT = 3

end