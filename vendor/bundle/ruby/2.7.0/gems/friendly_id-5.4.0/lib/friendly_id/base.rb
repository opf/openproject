module FriendlyId
=begin

## Setting Up FriendlyId in Your Model

To use FriendlyId in your ActiveRecord models, you must first either extend or
include the FriendlyId module (it makes no difference), then invoke the
{FriendlyId::Base#friendly_id friendly_id} method to configure your desired
options:

    class Foo < ActiveRecord::Base
      include FriendlyId
      friendly_id :bar, :use => [:slugged, :simple_i18n]
    end

The most important option is `:use`, which you use to tell FriendlyId which
addons it should use. See the documentation for {FriendlyId::Base#friendly_id} for a list of all
available addons, or skim through the rest of the docs to get a high-level
overview.

*A note about single table inheritance (STI): you must extend FriendlyId in
all classes that participate in STI, both your parent classes and their
children.*

### The Default Setup: Simple Models

The simplest way to use FriendlyId is with a model that has a uniquely indexed
column with no spaces or special characters, and that is seldom or never
updated. The most common example of this is a user name:

    class User < ActiveRecord::Base
      extend FriendlyId
      friendly_id :login
      validates_format_of :login, :with => /\A[a-z0-9]+\z/i
    end

    @user = User.friendly.find "joe"   # the old User.find(1) still works, too
    @user.to_param                     # returns "joe"
    redirect_to @user                  # the URL will be /users/joe

In this case, FriendlyId assumes you want to use the column as-is; it will never
modify the value of the column, and your application should ensure that the
value is unique and admissible in a URL:

    class City < ActiveRecord::Base
      extend FriendlyId
      friendly_id :name
    end

    @city.friendly.find "Viña del Mar"
    redirect_to @city # the URL will be /cities/Viña%20del%20Mar

Writing the code to process an arbitrary string into a good identifier for use
in a URL can be repetitive and surprisingly tricky, so for this reason it's
often better and easier to use {FriendlyId::Slugged slugs}.

=end
  module Base

    # Configure FriendlyId's behavior in a model.
    #
    #     class Post < ActiveRecord::Base
    #       extend FriendlyId
    #       friendly_id :title, :use => :slugged
    #     end
    #
    # When given the optional block, this method will yield the class's instance
    # of {FriendlyId::Configuration} to the block before evaluating other
    # arguments, so configuration values set in the block may be overwritten by
    # the arguments. This order was chosen to allow passing the same proc to
    # multiple models, while being able to override the values it sets. Here is
    # a contrived example:
    #
    #     $friendly_id_config_proc = Proc.new do |config|
    #       config.base = :name
    #       config.use :slugged
    #     end
    #
    #     class Foo < ActiveRecord::Base
    #       extend FriendlyId
    #       friendly_id &$friendly_id_config_proc
    #     end
    #
    #     class Bar < ActiveRecord::Base
    #       extend FriendlyId
    #       friendly_id :title, &$friendly_id_config_proc
    #     end
    #
    # However, it's usually better to use {FriendlyId.defaults} for this:
    #
    #     FriendlyId.defaults do |config|
    #       config.base = :name
    #       config.use :slugged
    #     end
    #
    #     class Foo < ActiveRecord::Base
    #       extend FriendlyId
    #     end
    #
    #     class Bar < ActiveRecord::Base
    #       extend FriendlyId
    #       friendly_id :title
    #     end
    #
    # In general you should use the block syntax either because of your personal
    # aesthetic preference, or because you need to share some functionality
    # between multiple models that can't be well encapsulated by
    # {FriendlyId.defaults}.
    #
    # ### Order Method Calls in a Block vs Ordering Options
    #
    # When calling this method without a block, you may set the hash options in
    # any order.
    #
    # However, when using block-style invocation, be sure to call
    # FriendlyId::Configuration's {FriendlyId::Configuration#use use} method
    # *prior* to the associated configuration options, because it will include
    # modules into your class, and these modules in turn may add required
    # configuration options to the `@friendly_id_configuraton`'s class:
    #
    #     class Person < ActiveRecord::Base
    #       friendly_id do |config|
    #         # This will work
    #         config.use :slugged
    #         config.sequence_separator = ":"
    #       end
    #     end
    #
    #     class Person < ActiveRecord::Base
    #       friendly_id do |config|
    #         # This will fail
    #         config.sequence_separator = ":"
    #         config.use :slugged
    #       end
    #     end
    #
    # ### Including Your Own Modules
    #
    # Because :use can accept a name or a Module, {FriendlyId.defaults defaults}
    # can be a convenient place to set up behavior common to all classes using
    # FriendlyId. You can include any module, or more conveniently, define one
    # on-the-fly. For example, let's say you want to make
    # [Babosa](http://github.com/norman/babosa) the default slugging library in
    # place of Active Support, and transliterate all slugs from Russian Cyrillic
    # to ASCII:
    #
    #     require "babosa"
    #
    #     FriendlyId.defaults do |config|
    #       config.base = :name
    #       config.use :slugged
    #       config.use Module.new {
    #         def normalize_friendly_id(text)
    #           text.to_slug.normalize! :transliterations => [:russian, :latin]
    #         end
    #       }
    #     end
    #
    #
    # @option options [Symbol,Module] :use The addon or name of an addon to use.
    #   By default, FriendlyId provides {FriendlyId::Slugged :slugged},
    #   {FriendlyId::Reserved :finders}, {FriendlyId::History :history},
    #   {FriendlyId::Reserved :reserved}, {FriendlyId::Scoped :scoped}, and
    #   {FriendlyId::SimpleI18n :simple_i18n}.
    #
    # @option options [Array] :reserved_words Available when using `:reserved`,
    #   which is loaded by default. Sets an array of words banned for use as
    #   the basis of a friendly_id. By default this includes "edit" and "new".
    #
    # @option options [Symbol] :scope Available when using `:scoped`.
    #   Sets the relation or column used to scope generated friendly ids. This
    #   option has no default value.
    #
    # @option options [Symbol] :sequence_separator Available when using `:slugged`.
    #   Configures the sequence of characters used to separate a slug from a
    #   sequence. Defaults to `-`.
    #
    # @option options [Symbol] :slug_column Available when using `:slugged`.
    #   Configures the name of the column where FriendlyId will store the slug.
    #   Defaults to `:slug`.
    #
    # @option options [Integer] :slug_limit Available when using `:slugged`.
    #   Configures the limit of the slug. This option has no default value.
    #
    # @option options [Symbol] :slug_generator_class Available when using `:slugged`.
    #   Sets the class used to generate unique slugs. You should not specify this
    #   unless you're doing some extensive hacking on FriendlyId. Defaults to
    #   {FriendlyId::SlugGenerator}.
    #
    # @yield Provides access to the model class's friendly_id_config, which
    #   allows an alternate configuration syntax, and conditional configuration
    #   logic.
    #
    # @option options [Symbol,Boolean] :dependent Available when using `:history`.
    #   Sets the value used for the slugged association's dependent option. Use
    #   `false` if you do not want to dependently destroy the associated slugged
    #   record. Defaults to `:destroy`.
    #
    # @option options [Symbol] :routes When set to anything other than :friendly,
    #   ensures that all routes generated by default do *not* use the slug.  This
    #   allows `form_for` and `polymorphic_path` to continue to generate paths like
    #   `/team/1` instead of `/team/number-one`.  You can still generate paths
    #   like the latter using: team_path(team.slug).  When set to :friendly, or
    #   omitted, the default friendly_id behavior is maintained.
    #
    # @yieldparam config The model class's {FriendlyId::Configuration friendly_id_config}.
    def friendly_id(base = nil, options = {}, &block)
      yield friendly_id_config if block_given?
      friendly_id_config.dependent = options.delete :dependent
      friendly_id_config.use options.delete :use
      friendly_id_config.send :set, base ? options.merge(:base => base) : options
      include Model
    end

    # Returns a scope that includes the friendly finders.
    # @see FriendlyId::FinderMethods
    def friendly
      # Guess what? This causes Rails to invoke `extend` on the scope, which has
      # the well-known effect of blowing away Ruby's method cache. It would be
      # possible to make this more performant by subclassing the model's
      # relation class, extending that, and returning an instance of it in this
      # method. FriendlyId 4.0 did something similar. However in 5.0 I've
      # decided to only use Rails's public API in order to improve compatibility
      # and maintainability. If you'd like to improve the performance, your
      # efforts would be best directed at improving it at the root cause
      # of the problem - in Rails - because it would benefit more people.
      all.extending(friendly_id_config.finder_methods)
    end

    # Returns the model class's {FriendlyId::Configuration friendly_id_config}.
    # @note In the case of Single Table Inheritance (STI), this method will
    #   duplicate the parent class's FriendlyId::Configuration and relation class
    #   on first access. If you're concerned about thread safety, then be sure
    #   to invoke {#friendly_id} in your class for each model.
    def friendly_id_config
      @friendly_id_config ||= base_class.friendly_id_config.dup.tap do |config|
        config.model_class = self
      end
    end

    def primary_key_type
      @primary_key_type ||= columns_hash[primary_key].type
    end
  end

  # Instance methods that will be added to all classes using FriendlyId.
  module Model
    def self.included(model_class)
      return if model_class.respond_to?(:friendly)
    end

    # Convenience method for accessing the class method of the same name.
    def friendly_id_config
      self.class.friendly_id_config
    end

    # Get the instance's friendly_id.
    def friendly_id
      send friendly_id_config.query_field
    end

    # Either the friendly_id, or the numeric id cast to a string.
    def to_param
      if friendly_id_config.routes == :friendly
        friendly_id.presence.to_param || super
      else
        super
      end
    end

    # Clears slug on duplicate records when calling `dup`.
    def dup
      super.tap { |duplicate| duplicate.slug = nil if duplicate.respond_to?('slug=') }
    end
  end
end
