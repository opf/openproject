class FilenameHelper
  # Remove characters that could cause problems on popular OSses
  # => A string that does not start with a space or dot and does not contain any of \/:*?"<>|
  def self.sane_filename(str)
    str.gsub(/^[ \.]/,"").gsub(/[\\\/:\*\?"<>|"]/, "_")
  end
end