# frozen_string_literal: true

module Grape
  module DSL
    module Headers
      # Set an individual header or retrieve
      # all headers that have been set.
      def header(key = nil, val = nil)
        if key
          val ? header[key.to_s] = val : header.delete(key.to_s)
        else
          @header ||= {}
        end
      end
      alias headers header
    end
  end
end
