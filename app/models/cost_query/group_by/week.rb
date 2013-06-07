class CostQuery::GroupBy
  class Week < Base

    def self.label
      I18n.t(:label_week_reporting)
    end
  end
end
