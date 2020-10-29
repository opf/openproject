module Disposable
  # Composition allows renaming properties and combining one or more objects
  # in order to expose a different API.
  # It can be configured from any Representable schema.
  #
  #   class AlbumTwin < Disposable::Twin
  #     property :name, on: :artist
  #   end
  #
  #   class AlbumExpose < Disposable::Composition
  #     from AlbumTwin
  #   end
  #
  #   AlbumExpose.new(artist: OpenStruct.new(name: "AFI")).name #=> "AFI"
  class Composition < Expose
    def initialize(models)
      models.each do |name, model|
        instance_variable_set(:"@#{name}", model)
      end

      @_models = models
    end

    # Allows accessing the contained models.
    def [](name)
      instance_variable_get("@#{name}")
    end

    def each(&block)
      # TODO: test me.
      @_models.values.each(&block)
    end

  private
    def self.accessors!(public_name, private_name, definition)
      model = definition[:on]
      define_method("#{public_name}")  { self[model].send("#{private_name}") }
      define_method("#{public_name}=") { |*args| self[model].send("#{private_name}=", *args) }
    end
  end
end