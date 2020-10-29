require 'uri'
require 'spreadsheet/encodings'

module Spreadsheet
  ##
  # The Link class. Is a Subclass of String, which lets you treat a Cell that
  # contains a Link just as if it was a String (containing the link's description
  # if there is one or the url with fragment otherwise), but gives you access
  # to the url, fragment and target_frame if you need it.
  #
  #
  # Interesting Attributes
  # #url          :: The Uniform Resource Location this Link points to.
  # #fragment     :: Also called text mark: http://example.com/page.html#fragment
  # #target_frame :: Which frame a Link should be opened in, should also support
  #                  the special frames _blank, _parent, _self and _top.
  # #dos          :: Excel may store a DOS-Filename together with the long
  #                  Filename introduced in VFAT. You probably will not need this,
  #                  but if you do, here is where you can find it.
  class Link < String
    include Encodings
    attr_accessor :target_frame, :url, :dos, :fragment
    def initialize url='', description=url, fragment=nil
      super description
      @url = url
      @fragment = fragment
    end
    ##
    # The Url with the fragment appended if present.
    def href
      href = (@url || @dos).to_s.dup
      if @fragment
        href << client('#', 'UTF-8') << @fragment
      end
      href
    end
    ##
    # Attempts to parse the output of href. May raise a URI::InvalidURIError
    def to_uri
      URI.parse href
    end
  end
end
