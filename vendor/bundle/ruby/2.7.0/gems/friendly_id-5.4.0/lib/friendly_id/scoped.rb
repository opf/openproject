require "friendly_id/slugged"

module FriendlyId

=begin

## Unique Slugs by Scope

The {FriendlyId::Scoped} module allows FriendlyId to generate unique slugs
within a scope.

This allows, for example, two restaurants in different cities to have the slug
`joes-diner`:

    class Restaurant < ActiveRecord::Base
      extend FriendlyId
      belongs_to :city
      friendly_id :name, :use => :scoped, :scope => :city
    end

    class City < ActiveRecord::Base
      extend FriendlyId
      has_many :restaurants
      friendly_id :name, :use => :slugged
    end

    City.friendly.find("seattle").restaurants.friendly.find("joes-diner")
    City.friendly.find("chicago").restaurants.friendly.find("joes-diner")

Without :scoped in this case, one of the restaurants would have the slug
`joes-diner` and the other would have `joes-diner-f9f3789a-daec-4156-af1d-fab81aa16ee5`.

The value for the `:scope` option can be the name of a `belongs_to` relation, or
a column.

Additionally, the `:scope` option can receive an array of scope values:

    class Cuisine < ActiveRecord::Base
      extend FriendlyId
      has_many :restaurants
      friendly_id :name, :use => :slugged
    end

    class City < ActiveRecord::Base
      extend FriendlyId
      has_many :restaurants
      friendly_id :name, :use => :slugged
    end

    class Restaurant < ActiveRecord::Base
      extend FriendlyId
      belongs_to :city
      friendly_id :name, :use => :scoped, :scope => [:city, :cuisine]
    end

All supplied values will be used to determine scope.

### Finding Records by Friendly ID

If you are using scopes your friendly ids may not be unique, so a simple find
like:

    Restaurant.friendly.find("joes-diner")

may return the wrong record. In these cases it's best to query through the
relation:

    @city.restaurants.friendly.find("joes-diner")

Alternatively, you could pass the scope value as a query parameter:

    Restaurant.where(:city_id => @city.id).friendly.find("joes-diner")


### Finding All Records That Match a Scoped ID

Query the slug column directly:

    Restaurant.where(:slug => "joes-diner")

### Routes for Scoped Models

Recall that FriendlyId is a database-centric library, and does not set up any
routes for scoped models. You must do this yourself in your application. Here's
an example of one way to set this up:

    # in routes.rb
    resources :cities do
      resources :restaurants
    end

    # in views
    <%= link_to 'Show', [@city, @restaurant] %>

    # in controllers
    @city = City.friendly.find(params[:city_id])
    @restaurant = @city.restaurants.friendly.find(params[:id])

    # URLs:
    http://example.org/cities/seattle/restaurants/joes-diner
    http://example.org/cities/chicago/restaurants/joes-diner

=end
  module Scoped

    # FriendlyId::Config.use will invoke this method when present, to allow
    # loading dependent modules prior to overriding them when necessary.
    def self.setup(model_class)
      model_class.friendly_id_config.use :slugged
    end

    # Sets up behavior and configuration options for FriendlyId's scoped slugs
    # feature.
    def self.included(model_class)
      model_class.class_eval do
        friendly_id_config.class.send :include, Configuration
      end
    end

    def serialized_scope
      friendly_id_config.scope_columns.sort.map { |column| "#{column}:#{send(column)}" }.join(",")
    end

    def scope_for_slug_generator
      if friendly_id_config.uses?(:History)
        return super
      end
      relation = self.class.base_class.unscoped.friendly
      friendly_id_config.scope_columns.each do |column|
        relation = relation.where(column => send(column))
      end
      primary_key_name = self.class.primary_key
      relation.where(self.class.arel_table[primary_key_name].not_eq(send(primary_key_name)))
    end
    private :scope_for_slug_generator

    def slug_generator
      friendly_id_config.slug_generator_class.new(scope_for_slug_generator, friendly_id_config)
    end
    private :slug_generator

    def should_generate_new_friendly_id?
      (changed & friendly_id_config.scope_columns).any? || super
    end

    # This module adds the `:scope` configuration option to
    # {FriendlyId::Configuration FriendlyId::Configuration}.
    module Configuration

      # Gets the scope value.
      #
      # When setting this value, the argument should be a symbol referencing a
      # `belongs_to` relation, or a column.
      #
      # @return Symbol The scope value
      attr_accessor :scope

      # Gets the scope columns.
      #
      # Checks to see if the `:scope` option passed to
      # {FriendlyId::Base#friendly_id} refers to a relation, and if so, returns
      # the realtion's foreign key. Otherwise it assumes the option value was
      # the name of column and returns it cast to a String.
      #
      # @return String The scope column
      def scope_columns
        [@scope].flatten.map { |s| (reflection_foreign_key(s) or s).to_s }
      end

      private

      def reflection_foreign_key(scope)
        reflection = model_class.reflections[scope] || model_class.reflections[scope.to_s]
        reflection.try(:foreign_key)
      end
    end
  end
end
