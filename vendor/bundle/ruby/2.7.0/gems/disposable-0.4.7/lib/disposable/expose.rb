module Disposable
  # Expose allows renaming properties in order to expose a different API.
  # It can be configured from any Representable schema.
  #
  #   class AlbumTwin < Disposable::Twin
  #     property :name, from: :title
  #   end
  #
  #   class AlbumExpose < Disposable::Expose
  #     from AlbumTwin
  #   end
  #
  #   AlbumExpose.new(OpenStruct.new(title: "AFI")).name #=> "AFI"
  class Expose
    class << self
      def from(schema)
        schema.each do |definition|
          process_definition!(definition)
        end
        self
      end

    private
      def process_definition!(definition)
        public_name  = definition[:name]
        private_name = definition[:private_name] || public_name

        accessors!(public_name, private_name, definition)
      end

      def accessors!(public_name, private_name, definition)
        define_method("#{public_name}")  { @model.send("#{private_name}") }
        define_method("#{public_name}=") { |*args| @model.send("#{private_name}=", *args) }
      end
    end


    def initialize(model)
      @model = model
    end

    module Save
      def save
        @model.save # FIXME: block?
      end
    end
    include Save
  end
end