class CostQuery::Result < Report::Result
  module BaseAdditions
    def inspect
      "<##{self.class}: @fields=#{fields.inspect} @type=#{type.inspect} " \
      "@size=#{size} @count=#{count} @units=#{units} @real_costs=#{real_costs}>"
    end

    def display_costs?
      display_costs > 0
    end
  end

  class Base < Report::Result::Base
    include BaseAdditions
  end

  class DirectResult < Report::Result::DirectResult
    include BaseAdditions
    def display_costs
      self["display_costs"].to_i
    end

    def real_costs
      (self["real_costs"] || 0).to_d if display_costs? # FIXME: default value here?
    end
  end

  class WrappedResult < Report::Result::WrappedResult
    include BaseAdditions
    def display_costs
      (sum_for :display_costs) >= 1 ? 1 : 0
    end

    def real_costs
      sum_for :real_costs if display_costs?
    end
  end
end
