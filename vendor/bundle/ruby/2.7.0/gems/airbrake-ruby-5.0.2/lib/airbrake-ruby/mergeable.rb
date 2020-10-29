module Airbrake
  # Mergeable adds the `#merge` method, so that we don't need to define it in
  # all of performance models every time we add a model.
  #
  # @since 4.9.0
  # @api private
  module Mergeable
    def merge(_other)
      nil
    end
  end
end
