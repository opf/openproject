module OpenProject::Backlogs::Burndown
  unloadable

  class Series < Array
    def initialize(*args)
      @unit = args.pop
      @name = args.pop.to_sym
      @display = true

      raise "Unsupported unit '#{@unit}'" unless [:points, :hours].include? @unit
      super(*args)
    end

    attr_reader :unit
    attr_reader :name
    attr_accessor :display
  end
end
