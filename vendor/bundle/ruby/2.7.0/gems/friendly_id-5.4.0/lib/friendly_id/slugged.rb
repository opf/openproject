# encoding: utf-8
require "friendly_id/slug_generator"
require "friendly_id/candidates"

module FriendlyId
=begin

## Slugged Models

FriendlyId can use a separate column to store slugs for models which require
some text processing.

For example, blog applications typically use a post title to provide the basis
of a search engine friendly URL. Such identifiers typically lack uppercase
characters, use ASCII to approximate UTF-8 characters, and strip out other
characters which may make them aesthetically unappealing or error-prone when
used in a URL.

    class Post < ActiveRecord::Base
      extend FriendlyId
      friendly_id :title, :use => :slugged
    end

    @post = Post.create(:title => "This is the first post!")
    @post.friendly_id   # returns "this-is-the-first-post"
    redirect_to @post   # the URL will be /posts/this-is-the-first-post

In general, use slugs by default unless you know for sure you don't need them.
To activate the slugging functionality, use the {FriendlyId::Slugged} module.

FriendlyId will generate slugs from a method or column that you specify, and
store them in a field in your model. By default, this field must be named
`:slug`, though you may change this using the
{FriendlyId::Slugged::Configuration#slug_column slug_column} configuration
option. You should add an index to this column, and in most cases, make it
unique. You may also wish to constrain it to NOT NULL, but this depends on your
app's behavior and requirements.

### Example Setup

    # your model
    class Post < ActiveRecord::Base
      extend FriendlyId
      friendly_id :title, :use => :slugged
      validates_presence_of :title, :slug, :body
    end

    # a migration
    class CreatePosts < ActiveRecord::Migration
      def self.up
        create_table :posts do |t|
          t.string :title, :null => false
          t.string :slug, :null => false
          t.text :body
        end

        add_index :posts, :slug, :unique => true
      end

      def self.down
        drop_table :posts
      end
    end

### Working With Slugs

#### Formatting

By default, FriendlyId uses Active Support's
[parameterize](http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-parameterize)
method to create slugs. This method will intelligently replace spaces with
dashes, and Unicode Latin characters with ASCII approximations:

    movie = Movie.create! :title => "Der Preis fürs Überleben"
    movie.slug #=> "der-preis-furs-uberleben"

#### Column or Method?

FriendlyId always uses a method as the basis of the slug text - not a column. At
first glance, this may sound confusing, but remember that Active Record provides
methods for each column in a model's associated table, and that's what
FriendlyId uses.

Here's an example of a class that uses a custom method to generate the slug:

    class Person < ActiveRecord::Base
      extend FriendlyId
      friendly_id :name_and_location, use: :slugged

      def name_and_location
        "#{name} from #{location}"
      end
    end

    bob = Person.create! :name => "Bob Smith", :location => "New York City"
    bob.friendly_id #=> "bob-smith-from-new-york-city"

FriendlyId refers to this internally as the "base" method.

#### Uniqueness

When you try to insert a record that would generate a duplicate friendly id,
FriendlyId will append a UUID to the generated slug to ensure uniqueness:

    car = Car.create :title => "Peugeot 206"
    car2 = Car.create :title => "Peugeot 206"

    car.friendly_id #=> "peugeot-206"
    car2.friendly_id #=> "peugeot-206-f9f3789a-daec-4156-af1d-fab81aa16ee5"

Previous versions of FriendlyId appended a numeric sequence to make slugs
unique, but this was removed to simplify using FriendlyId in concurrent code.

#### Candidates

Since UUIDs are ugly, FriendlyId provides a "slug candidates" functionality to
let you specify alternate slugs to use in the event the one you want to use is
already taken. For example:

    class Restaurant < ActiveRecord::Base
      extend FriendlyId
      friendly_id :slug_candidates, use: :slugged

      # Try building a slug based on the following fields in
      # increasing order of specificity.
      def slug_candidates
        [
          :name,
          [:name, :city],
          [:name, :street, :city],
          [:name, :street_number, :street, :city]
        ]
      end
    end

    r1 = Restaurant.create! name: 'Plaza Diner', city: 'New Paltz'
    r2 = Restaurant.create! name: 'Plaza Diner', city: 'Kingston'

    r1.friendly_id  #=> 'plaza-diner'
    r2.friendly_id  #=> 'plaza-diner-kingston'

To use candidates, make your FriendlyId base method return an array. The
method need not be named `slug_candidates`; it can be anything you want. The
array may contain any combination of symbols, strings, procs or lambdas and
will be evaluated lazily and in order. If you include symbols, FriendlyId will
invoke a method on your model class with the same name. Strings will be
interpreted literally. Procs and lambdas will be called and their return values
used as the basis of the friendly id. If none of the candidates can generate a
unique slug, then FriendlyId will append a UUID to the first candidate as a
last resort.

#### Sequence Separator

By default, FriendlyId uses a dash to separate the slug from a sequence.

You can change this with the {FriendlyId::Slugged::Configuration#sequence_separator
sequence_separator} configuration option.

#### Providing Your Own Slug Processing Method

You can override {FriendlyId::Slugged#normalize_friendly_id} in your model for
total control over the slug format. It will be invoked for any generated slug,
whether for a single slug or for slug candidates.

#### Deciding When to Generate New Slugs

As of FriendlyId 5.0, slugs are only generated when the `slug` field is nil. If
you want a slug to be regenerated,set the slug field to nil:

    restaurant.friendly_id # joes-diner
    restaurant.name = "The Plaza Diner"
    restaurant.save!
    restaurant.friendly_id # joes-diner
    restaurant.slug = nil
    restaurant.save!
    restaurant.friendly_id # the-plaza-diner

You can also override the
{FriendlyId::Slugged#should_generate_new_friendly_id?} method, which lets you
control exactly when new friendly ids are set:

    class Post < ActiveRecord::Base
      extend FriendlyId
      friendly_id :title, :use => :slugged

      def should_generate_new_friendly_id?
        title_changed?
      end
    end

If you want to extend the default behavior but add your own conditions,
don't forget to invoke `super` from your implementation:

    class Category < ActiveRecord::Base
      extend FriendlyId
      friendly_id :name, :use => :slugged

      def should_generate_new_friendly_id?
        name_changed? || super
      end
    end

#### Locale-specific Transliterations

Active Support's `parameterize` uses
[transliterate](http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-transliterate),
which in turn can use I18n's transliteration rules to consider the current
locale when replacing Latin characters:

    # config/locales/de.yml
    de:
      i18n:
        transliterate:
          rule:
            ü: "ue"
            ö: "oe"
            etc...

    movie = Movie.create! :title => "Der Preis fürs Überleben"
    movie.slug #=> "der-preis-fuers-ueberleben"

This functionality was in fact taken from earlier versions of FriendlyId.

#### Gotchas: Common Problems

FriendlyId uses a before_validation callback to generate and set the slug. This
means that if you create two model instances before saving them, it's possible
they will generate the same slug, and the second save will fail.

This can happen in two fairly normal cases: the first, when a model using nested
attributes creates more than one record for a model that uses friendly_id. The
second, in concurrent code, either in threads or multiple processes.

To solve the nested attributes issue, I recommend simply avoiding them when
creating more than one nested record for a model that uses FriendlyId. See [this
Github issue](https://github.com/norman/friendly_id/issues/185) for discussion.

=end
  module Slugged

    # Sets up behavior and configuration options for FriendlyId's slugging
    # feature.
    def self.included(model_class)
      model_class.friendly_id_config.instance_eval do
        self.class.send :include, Configuration
        self.slug_generator_class     ||= SlugGenerator
        defaults[:slug_column]        ||= 'slug'
        defaults[:sequence_separator] ||= '-'
      end
      model_class.before_validation :set_slug
      model_class.after_validation :unset_slug_if_invalid
    end

    # Process the given value to make it suitable for use as a slug.
    #
    # This method is not intended to be invoked directly; FriendlyId uses it
    # internally to process strings into slugs.
    #
    # However, if FriendlyId's default slug generation doesn't suit your needs,
    # you can override this method in your model class to control exactly how
    # slugs are generated.
    #
    # ### Example
    #
    #     class Person < ActiveRecord::Base
    #       extend FriendlyId
    #       friendly_id :name_and_location
    #
    #       def name_and_location
    #         "#{name} from #{location}"
    #       end
    #
    #       # Use default slug, but upper case and with underscores
    #       def normalize_friendly_id(string)
    #         super.upcase.gsub("-", "_")
    #       end
    #     end
    #
    #     bob = Person.create! :name => "Bob Smith", :location => "New York City"
    #     bob.friendly_id #=> "BOB_SMITH_FROM_NEW_YORK_CITY"
    #
    # ### More Resources
    #
    # You might want to look into Babosa[https://github.com/norman/babosa],
    # which is the slugging library used by FriendlyId prior to version 4, which
    # offers some specialized functionality missing from Active Support.
    #
    # @param [#to_s] value The value used as the basis of the slug.
    # @return The candidate slug text, without a sequence.
    def normalize_friendly_id(value)
      value = value.to_s.parameterize
      value = value[0...friendly_id_config.slug_limit] if friendly_id_config.slug_limit
      value
    end

    # Whether to generate a new slug.
    #
    # You can override this method in your model if, for example, you only want
    # slugs to be generated once, and then never updated.
    def should_generate_new_friendly_id?
      send(friendly_id_config.slug_column).nil? && !send(friendly_id_config.base).nil?
    end

    # Public: Resolve conflicts.
    #
    # This method adds UUID to first candidate and truncates (if `slug_limit` is set).
    #
    # Examples:
    #
    #   resolve_friendly_id_conflict(['12345'])
    #   # => '12345-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    #
    #   FriendlyId.defaults { |config| config.slug_limit = 40 }
    #   resolve_friendly_id_conflict(['12345'])
    #   # => '123-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    #
    # candidates - the Array with candidates.
    #
    # Returns the String with new slug.
    def resolve_friendly_id_conflict(candidates)
      uuid = SecureRandom.uuid
      [
        apply_slug_limit(candidates.first, uuid),
        uuid
      ].compact.join(friendly_id_config.sequence_separator)
    end

    # Private: Apply slug limit to candidate.
    #
    # candidate - the String with candidate.
    # uuid      - the String with UUID.
    #
    # Return the String with truncated candidate.
    def apply_slug_limit(candidate, uuid)
      return candidate unless candidate && friendly_id_config.slug_limit

      candidate[0...candidate_limit(uuid)]
    end
    private :apply_slug_limit

    # Private: Get max length of candidate.
    #
    # uuid - the String with UUID.
    #
    # Returns the Integer with max length.
    def candidate_limit(uuid)
      [
        friendly_id_config.slug_limit - uuid.size - friendly_id_config.sequence_separator.size,
        0
      ].max
    end
    private :candidate_limit

    # Sets the slug.
    def set_slug(normalized_slug = nil)
      if should_generate_new_friendly_id?
        candidates = FriendlyId::Candidates.new(self, normalized_slug || send(friendly_id_config.base))
        slug = slug_generator.generate(candidates) || resolve_friendly_id_conflict(candidates)
        send "#{friendly_id_config.slug_column}=", slug
      end
    end
    private :set_slug

    def scope_for_slug_generator
      scope = self.class.base_class.unscoped
      scope = scope.friendly unless scope.respond_to?(:exists_by_friendly_id?)
      primary_key_name = self.class.primary_key
      scope.where(self.class.base_class.arel_table[primary_key_name].not_eq(send(primary_key_name)))
    end
    private :scope_for_slug_generator

    def slug_generator
      friendly_id_config.slug_generator_class.new(scope_for_slug_generator, friendly_id_config)
    end
    private :slug_generator

    def unset_slug_if_invalid
      if errors[friendly_id_config.query_field].present? && attribute_changed?(friendly_id_config.query_field.to_s)
        diff = changes[friendly_id_config.query_field]
        send "#{friendly_id_config.slug_column}=", diff.first
      end
    end
    private :unset_slug_if_invalid

    # This module adds the `:slug_column`, and `:slug_limit`, and `:sequence_separator`,
    # and `:slug_generator_class` configuration options to
    # {FriendlyId::Configuration FriendlyId::Configuration}.
    module Configuration
      attr_writer :slug_column, :slug_limit, :sequence_separator
      attr_accessor :slug_generator_class

      # Makes FriendlyId use the slug column for querying.
      # @return String The slug column.
      def query_field
        slug_column
      end

      # The string used to separate a slug base from a numeric sequence.
      #
      # You can change the default separator by setting the
      # {FriendlyId::Slugged::Configuration#sequence_separator
      # sequence_separator} configuration option.
      # @return String The sequence separator string. Defaults to "`-`".
      def sequence_separator
        @sequence_separator ||= defaults[:sequence_separator]
      end

      # The column that will be used to store the generated slug.
      def slug_column
        @slug_column ||= defaults[:slug_column]
      end

      # The limit that will be used for slug.
      def slug_limit
        @slug_limit ||= defaults[:slug_limit]
      end
    end
  end
end
