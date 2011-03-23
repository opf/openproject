class VersionSetting < ActiveRecord::Base
  belongs_to :project
  belongs_to :version

  DISPLAY_NONE = 1
  DISPLAY_LEFT = 2
  DISPLAY_RIGHT = 3

  def display_right?
    self.display == DISPLAY_RIGHT
  end

  def display_right!
    self.display = DISPLAY_RIGHT
  end

  def display_left?
    self.display == DISPLAY_LEFT
  end

  def display_left!
    self.display = DISPLAY_LEFT
  end

  def display_none?
    self.display == DISPLAY_NONE
  end

  def display_none!
    self.display = DISPLAY_NONE
  end
end
