module Airbrake
  # Stashable should be included in any class that wants the ability to stash
  # arbitrary objects. It is mainly used by data objects that users can access
  # through filters.
  #
  # @since v4.4.0
  # @api private
  module Stashable
    # @return [Hash{Symbol=>Object}] the hash with arbitrary objects to be used
    #   in filters
    def stash
      @stash ||= {}
    end
  end
end
