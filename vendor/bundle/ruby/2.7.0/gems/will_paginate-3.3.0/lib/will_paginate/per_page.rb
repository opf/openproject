module WillPaginate
  module PerPage
    def per_page
      defined?(@per_page) ? @per_page : WillPaginate.per_page
    end

    def per_page=(limit)
      @per_page = limit.to_i
    end

    def self.extended(base)
      base.extend Inheritance if base.is_a? Class
    end

    module Inheritance
      def inherited(subclass)
        super
        subclass.per_page = self.per_page
      end
    end
  end

  extend PerPage

  # default number of items per page
  self.per_page = 30
end
