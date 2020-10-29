require 'time'

require 'messagebird/base'

module MessageBird
  class Lookup < MessageBird::Base
    attr_accessor :href, :countryCode, :countryPrefix, :phoneNumber, :type
    attr_reader :formats, :hlr

    def formats=(newFormats)
      @formats = Formats.new(newFormats)
    end

    def hlr=(newHLR)
      @hlr = HLR.new(newHLR)
    end
  end

  class Formats < MessageBird::Base
    attr_accessor :e164, :international, :national, :rfc3966
  end
end
