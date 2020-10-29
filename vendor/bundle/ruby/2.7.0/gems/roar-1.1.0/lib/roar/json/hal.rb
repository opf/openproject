require "roar/json"
require "representable/json/collection"
require "representable/json/hash"

module Roar
  module JSON
    # Including the JSON::HAL module in your representer will render and parse documents
    # following the HAL specification: http://stateless.co/hal_specification.html
    # Links will be embedded using the +_links+ key, nested resources with the +_embedded+ key.
    #
    # Embedded resources can be specified when calling #property or +collection using the
    # :embedded => true option.
    #
    # Link arrays can be defined using +::links+.
    #
    # CURIEs are specified with the - surprise - +::curie+ class method.
    #
    # Example:
    #
    #   module OrderRepresenter
    #     include Roar::JSON::HAL
    #
    #     property :id
    #     collection :items, :class => Item, :extend => ItemRepresenter, :embedded => true
    #
    #     link :self do
    #       "http://orders/#{id}"
    #     end
    #
    #     links :self do
    #       [{:lang => "en", :href => "http://en.hit"},
    #        {:lang => "de", :href => "http://de.hit"}]
    #     end
    #
    #     curies do
    #       [{:name => :doc,
    #         :href => "//docs/{rel}",
    #         :templated => true}
    #       ]
    #     end
    #   end
    #
    # Renders to
    #
    #   "{\"id\":1,\"_embedded\":{\"items\":[{\"value\":\"Beer\",\"_links\":{\"self\":{\"href\":\"http://items/Beer\"}}}]},\"_links\":{\"self\":{\"href\":\"http://orders/1\"}}}"
    module HAL
      def self.included(base)
        base.class_eval do
          include Roar::JSON
          include Links       # overwrites #links_definition_options.
          include Resources
          include LinksReader # gives us Decorator#links => {self=>< >}
        end
      end

      module Resources
        def to_hash(*)
          super.tap do |hash|
            embedded = {}
            representable_attrs.find_all do |dfn|
              name = dfn[:as] ? dfn[:as].(nil) : dfn.name # DISCUSS: should we simplify that in Representable?
              next unless dfn[:embedded] and fragment = hash.delete(name)
              embedded[name] = fragment
            end

            hash["_embedded"] = embedded if embedded.any?
            hash["_links"]    = hash.delete("_links") if hash["_links"] # always render _links after _embedded.
          end
        end

        def from_hash(hash, *)
          hash.fetch("_embedded", []).each { |name, fragment| hash[name] = fragment }
          super
        end
      end


      module Links
        def self.included(base)
          base.extend ClassMethods  # ::links_definition_options
          base.send :include, Hypermedia
          base.send :include, InstanceMethods
        end

        module InstanceMethods
          def _links
            links
          end

        private
          def prepare_link_for(href, options)
            return super(href, options) unless options[:array]  # returns Hyperlink.

            ArrayLink.new(options[:rel], href.collect { |opts| Hypermedia::Hyperlink.new(opts) })
          end
        end


        class SingleLink
          class Representer < Representable::Decorator
            include Representable::JSON::Hash

            def to_hash(*)
              hash = super
              {hash.delete("rel").to_s => hash}
            end
          end
        end

        class ArrayLink < Array
          def initialize(rel, links)
            @rel = rel
            super(links)
          end
          attr_reader :rel


          # [Hyperlink, Hyperlink]
          class Representer < Representable::Decorator
            include Representable::JSON::Collection

            items extend: SingleLink::Representer,
                  class:  Roar::Hypermedia::Hyperlink

            def to_hash(*)
              links = super.flat_map(&:values) # [{"self"=>{"href": ..}}, ..]

              { represented.rel.to_s => links } # {"self"=>[{"lang"=>"en", "href"=>"http://en.hit"}, {"lang"=>"de", "href"=>"http://de.hit"}]}
            end
          end
        end


        # Represents all links for  "_links":  [Hyperlink, [Hyperlink, Hyperlink]]
        class Representer < Representable::Decorator # links could be a simple collection property.
          include Representable::JSON::Collection

          # render: decorates represented.links with ArrayLink::R or SingleLink::R and calls #to_hash.
          # parse:  instantiate either Array or Hypermedia instance, decorate respectively, call #from_hash.
          items decorator: ->(options) { options[:input].is_a?(Array) ? ArrayLink::Representer : SingleLink::Representer },
                class:     ->(options) { options[:input].is_a?(Array) ? Array : Hypermedia::Hyperlink }

          def to_hash(options)
            super.inject({}) { |links, hash| links.merge!(hash) } # [{ rel=>{}, rel=>[{}, {}] }]
          end

          def from_hash(hash, *args)
            collection = hash.collect do |rel, value| # "self" => [{"href": "//"}, ] or "self" => {"href": "//"}
              value.is_a?(Array) ? value.collect { |link| link.merge("rel"=>rel) } : value.merge("rel"=>rel)
            end

            super(collection) # [{rel=>self, href=>//}, ..] or {rel=>self, href=>//}
          end
        end


        module ClassMethods
          def links_definition_options
            {
              # collection: false,
              :as       => :_links,
              decorator: Links::Representer,
              instance: ->(*) { Array.new }, # defined in InstanceMethods as this is executed in represented context.
              :exec_context => :decorator,
            }
          end

          # Use this to define link arrays. It accepts the shared rel attribute and an array of options per link object.
          #
          #   links :self do
          #     [{:lang => "en", :href => "http://en.hit"},
          #      {:lang => "de", :href => "http://de.hit"}]
          #   end
          def links(options, &block)
            options = {:rel => options} if options.is_a?(Symbol) || options.is_a?(String)
            options[:array] = true
            link(options, &block)
          end

          # Add a CURIEs link section as defined in
          #
          # curies do
          #   [{:name => :doc,
          #     :href => "//docs/{rel}",
          #     :templated => true}
          #   ]
          # end
          def curies(&block)
            links(:curies, &block)
          end
        end
      end

      # This is only helpful in client mode. It shouldn't be used per default.
      module LinksReader
        def links
          return unless @links
          tuples = @links.collect do |link|
            if link.is_a?(Array)
              next unless link.any?
              [link.first.rel, link]
            else
              [link.rel, link]
            end
          end.compact

          # tuples.to_h
          ::Hash[tuples] # TODO: tuples.to_h when dropping < 2.1.
        end
      end
    end
  end
end
