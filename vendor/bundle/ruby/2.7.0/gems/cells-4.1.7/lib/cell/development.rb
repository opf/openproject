module Cell
  module Development
    def self.included(base)
      base.instance_eval do
        def templates
          Templates.new
        end
      end
    end
  end
end