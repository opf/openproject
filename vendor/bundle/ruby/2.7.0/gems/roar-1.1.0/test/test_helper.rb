# require "pry"
require 'minitest/autorun'
require 'ostruct'

require 'roar/representer'
require 'roar/http_verbs'

require "roar/json"
require "roar/json/hal"

require "representable/debug"
require "pp"

module AttributesConstructor  # TODO: remove me.
  def initialize(attrs={})
    attrs.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end
end

# FIXME: provide a real #== for OpenStruct.
class Song < OpenStruct
  def ==(other)
    name == other.name and track == other.track
  end
end

class Album < OpenStruct
end

require "test_xml/mini_test"
require "roar/xml"


MiniTest::Spec.class_eval do
  def link(options)
    Roar::Hypermedia::Hyperlink.new(options)
  end

  def self.decorator_for(modules=[Roar::JSON, Roar::Hypermedia], &block)
    let(:decorator_class) do
      Class.new(Roar::Decorator) do
        include *modules.reverse

        instance_eval(&block)
      end
    end
  end

  def self.representer_for(modules=[Roar::JSON, Roar::Hypermedia], &block)
    let (:rpr) do
      Module.new do
        include *modules.reverse

        module_exec(&block)
      end
    end
  end
  def representer
    rpr # TODO: unify with representable.
  end

  def self.representer!(*args, &block)
    representer_for(*args, &block)
  end

  def self.verbs(&block)
    %w(get post put delete).each(&block)
  end
end


Roar::Hypermedia::Hyperlink.class_eval do
  def ==(b)
    @attrs == b.instance_variable_get(:@attrs)
  end
end
