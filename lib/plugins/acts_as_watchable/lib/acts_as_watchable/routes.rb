module OpenProject
  module Acts
    module Watchable
      module Routes
        mattr_accessor :models

        def self.watched?(object)
          @watchregexp.present? && @watchregexp.match(object).present?
        end

        def self.add_watched(watched)
          self.models ||= []

          self.models << watched.to_s unless self.models.include?(watched.to_s)

          @watchregexp = Regexp.new(self.models.join("|"))
        end
      end
    end
  end
end
