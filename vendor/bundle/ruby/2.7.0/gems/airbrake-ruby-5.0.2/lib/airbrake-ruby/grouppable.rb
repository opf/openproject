module Airbrake
  # Grouppable adds the `#groups` method, so that we don't need to define it in
  # all of performance models every time we add a model without groups.
  #
  # @since 4.9.0
  # @api private
  module Grouppable
    def groups
      {}
    end
  end
end
