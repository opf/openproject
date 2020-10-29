# frozen_string_literal: true

module Grape
  module Presenters
    class Presenter
      def self.represent(object, **_options)
        object
      end
    end
  end
end
