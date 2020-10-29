RSpec.describe Airbrake::Inspectable do
  let(:klass) do
    mod = subject
    Class.new do
      include(mod)

      def initialize
        @config = Airbrake::Config.new
        @filter_chain = nil
      end
    end
  end

  describe "#inspect" do
    it "displays object information" do
      instance = klass.new
      expect(instance.inspect).to match(/
        #<:0x\w+\s
          project_id=""\s
          project_key=""\s
          host="http.+"\s
          filter_chain=nil>
      /x)
    end
  end

  describe "#pretty_print" do
    it "displays object information in a beautiful way" do
      q = PP.new

      instance = klass.new
      # Guarding is needed to fix JRuby failure:
      # NoMethodError: undefined method `[]' for nil:NilClass
      q.guard_inspect_key { instance.pretty_print(q) }

      expect(q.output).to match(/
        #<:0x\w+\s
          project_id=""\s
          project_key=""\s
          host="http.+"\s
          filter_chain=nil
      /x)
    end
  end
end
