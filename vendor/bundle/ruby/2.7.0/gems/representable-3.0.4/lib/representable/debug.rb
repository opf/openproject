module Representable
  module Debug
    def update_properties_from(doc, options, format)
      puts
      puts "[Deserialize]........."
      puts "[Deserialize] document #{doc.inspect}"
      super
    end

    def create_representation_with(doc, options, format)
      puts
      puts "[Serialize]........."
      puts "[Serialize]"
      super
    end

    def representable_map(*)
      super.tap do |arr|
        arr.collect { |bin| bin.extend(Binding) }
      end
    end

    module Binding
      def evaluate_option(name, *args, &block)
        puts "=====#{self[name]}" if name ==:prepare
        puts (evaled = self[name]) ?
          "                #evaluate_option [#{name}]: eval!!!" :
          "                #evaluate_option [#{name}]: skipping"
        value = super
        puts "                #evaluate_option [#{name}]: --> #{value}" if evaled
        puts "                #evaluate_option [#{name}]: -->= #{args.first}" if name == :setter
        value
      end

      def parse_pipeline(*)
        super.extend(Pipeline::Debug)
      end

      def render_pipeline(*)
        super.extend(Pipeline::Debug)
      end
    end
  end


  module Pipeline::Debug
    def call(input, options)
      puts "Pipeline#call: #{inspect}"
      puts "               input: #{input.inspect}"
      super
    end

    def evaluate(block, memo, options)
      block.extend(Pipeline::Debug) if block.is_a?(Collect)

      puts "  Pipeline   :   -> #{_inspect_function(block)} "
      super.tap do |res|
        puts "  Pipeline   :     result: #{res.inspect}"
      end
    end

    def inspect
      functions = collect do |func|
        _inspect_function(func)
      end.join(", ")
      "#{self.class.to_s.split("::").last}[#{functions}]"
    end

    # prints SkipParse instead of <Proc>. i know, i can make this better, but not now.
    def _inspect_function(func)
      return func.extend(Pipeline::Debug).inspect if func.is_a?(Collect)
      return func unless func.is_a?(Proc)
      File.readlines(func.source_location[0])[func.source_location[1]-1].match(/^\s+(\w+)/)[1]
    end
  end
end

