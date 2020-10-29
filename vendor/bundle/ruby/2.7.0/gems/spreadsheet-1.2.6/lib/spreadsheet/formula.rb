module Spreadsheet
  ##
  # Formula implementation. At the moment this is just a placeholder.
  # You may access the last calculated #value, other attributes are needed for
  # writing the Formula back into modified Excel Files.
  class Formula
    attr_accessor :data, :value, :shared
  end
end
