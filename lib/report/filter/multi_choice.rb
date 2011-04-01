class Report::Filter
  class MultiChoice < Base

    dont_inherit :available_operators
    use '='

    def self.is_multiple_choice?
      true
    end
  end
end