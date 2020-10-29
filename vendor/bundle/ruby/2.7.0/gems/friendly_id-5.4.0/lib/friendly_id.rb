# encoding: utf-8
require 'active_record'
require "friendly_id/base"
require "friendly_id/object_utils"
require "friendly_id/configuration"
require "friendly_id/finder_methods"

=begin

## About FriendlyId

FriendlyId is an add-on to Ruby's Active Record that allows you to replace ids
in your URLs with strings:

    # without FriendlyId
    http://example.com/states/4323454

    # with FriendlyId
    http://example.com/states/washington

It requires few changes to your application code and offers flexibility,
performance and a well-documented codebase.

### Core Concepts

#### Slugs

The concept of *slugs* is at the heart of FriendlyId.

A slug is the part of a URL which identifies a page using human-readable
keywords, rather than an opaque identifier such as a numeric id. This can make
your application more friendly both for users and search engines.

#### Finders: Slugs Act Like Numeric IDs

To the extent possible, FriendlyId lets you treat text-based identifiers like
normal IDs. This means that you can perform finds with slugs just like you do
with numeric ids:

    Person.find(82542335)
    Person.friendly.find("joe")

=end
module FriendlyId

  autoload :History,             "friendly_id/history"
  autoload :Slug,                "friendly_id/slug"
  autoload :SimpleI18n,          "friendly_id/simple_i18n"
  autoload :Reserved,            "friendly_id/reserved"
  autoload :Scoped,              "friendly_id/scoped"
  autoload :Slugged,             "friendly_id/slugged"
  autoload :Finders,             "friendly_id/finders"
  autoload :SequentiallySlugged, "friendly_id/sequentially_slugged"

  # FriendlyId takes advantage of `extended` to do basic model setup, primarily
  # extending {FriendlyId::Base} to add {FriendlyId::Base#friendly_id
  # friendly_id} as a class method.
  #
  # Previous versions of FriendlyId simply patched ActiveRecord::Base, but this
  # version tries to be less invasive.
  #
  # In addition to adding {FriendlyId::Base#friendly_id friendly_id}, the class
  # instance variable +@friendly_id_config+ is added. This variable is an
  # instance of an anonymous subclass of {FriendlyId::Configuration}. This
  # allows subsequently loaded modules like {FriendlyId::Slugged} and
  # {FriendlyId::Scoped} to add functionality to the configuration class only
  # for the current class, rather than monkey patching
  # {FriendlyId::Configuration} directly. This isolates other models from large
  # feature changes an addon to FriendlyId could potentially introduce.
  #
  # The upshot of this is, you can have two Active Record models that both have
  # a @friendly_id_config, but each config object can have different methods
  # and behaviors depending on what modules have been loaded, without
  # conflicts.  Keep this in mind if you're hacking on FriendlyId.
  #
  # For examples of this, see the source for {Scoped.included}.
  def self.extended(model_class)
    return if model_class.respond_to? :friendly_id
    class << model_class
      alias relation_without_friendly_id relation
    end
    model_class.class_eval do
      extend Base
      @friendly_id_config = Class.new(Configuration).new(self)
      FriendlyId.defaults.call @friendly_id_config
      include Model
    end
  end

  # Allow developers to `include` FriendlyId or `extend` it.
  def self.included(model_class)
    model_class.extend self
  end

  # Set global defaults for all models using FriendlyId.
  #
  # The default defaults are to use the `:reserved` module and nothing else.
  #
  # @example
  #   FriendlyId.defaults do |config|
  #     config.base :name
  #     config.use :slugged
  #   end
  def self.defaults(&block)
    @defaults = block if block_given?
    @defaults ||= ->(config) {config.use :reserved}
  end

  # Set the ActiveRecord table name prefix to friendly_id_
  #
  # This makes 'slugs' into 'friendly_id_slugs' and also respects any
  # 'global' table_name_prefix set on ActiveRecord::Base.
  def self.table_name_prefix
    "#{ActiveRecord::Base.table_name_prefix}friendly_id_"
  end
end
