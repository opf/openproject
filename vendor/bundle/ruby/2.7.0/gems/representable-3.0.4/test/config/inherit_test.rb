require 'test_helper'

# tests defining representers in modules, decorators and classes and the inheritance when combined.

class ConfigInheritTest < MiniTest::Spec
  def assert_cloned(child, parent, property)
    child_def  = child.representable_attrs.get(property)
    parent_def = parent.representable_attrs.get(property)

    child_def.merge!(:alias => property)

    child_def[:alias].wont_equal parent_def[:alias]
    child_def.object_id.wont_equal parent_def.object_id
  end
  # class Object

  # end
  module GenreModule
    include Representable::Hash
    property :genre
  end


  # in Decorator ------------------------------------------------
  class Decorator < Representable::Decorator
    include Representable::Hash
    property :title
    property :artist do
      property :id
    end
  end

  it { Decorator.definitions.keys.must_equal ["title", "artist"] }

  # in inheriting Decorator

  class InheritingDecorator < Decorator
    property :location
  end

  it { InheritingDecorator.definitions.keys.must_equal ["title", "artist", "location"] }
  it { assert_cloned(InheritingDecorator, Decorator, "title") }
  it do
    InheritingDecorator.representable_attrs.get(:artist).representer_module.object_id.wont_equal Decorator.representable_attrs.get(:artist).representer_module.object_id
  end

  # in inheriting and including Decorator

  class InheritingAndIncludingDecorator < Decorator
    include GenreModule
    property :location
  end

  it { InheritingAndIncludingDecorator.definitions.keys.must_equal ["title", "artist", "genre", "location"] }
  it { assert_cloned(InheritingAndIncludingDecorator, GenreModule, :genre) }


  # in module ---------------------------------------------------
  module Module
    include Representable
    property :title
  end

  it { Module.definitions.keys.must_equal ["title"] }


  # in module including module
  module SubModule
    include Representable
    include Module

    property :location
  end

  it { SubModule.definitions.keys.must_equal ["title", "location"] }
  it { assert_cloned(SubModule, Module, :title) }

  # including preserves order
  module IncludingModule
    include Representable
    property :genre
    include Module

    property :location
  end

  it { IncludingModule.definitions.keys.must_equal ["genre", "title", "location"] }


  # included in class -------------------------------------------
  class Class
    include Representable
    include IncludingModule
  end

  it { Class.definitions.keys.must_equal ["genre", "title", "location"] }
  it { assert_cloned(Class, IncludingModule, :title) }
  it { assert_cloned(Class, IncludingModule, :location) }
  it { assert_cloned(Class, IncludingModule, :genre) }

  # included in class with order
  class DefiningClass
    include Representable
    property :street_cred
    include IncludingModule
  end

  it { DefiningClass.definitions.keys.must_equal ["street_cred", "genre", "title", "location"] }

  # in class
  class RepresenterClass
    include Representable
    property :title
  end

  it { RepresenterClass.definitions.keys.must_equal ["title"] }


  # in inheriting class
  class InheritingClass < RepresenterClass
    include Representable
    property :location
  end

  it { InheritingClass.definitions.keys.must_equal ["title", "location"] }
  it { assert_cloned(InheritingClass, RepresenterClass, :title) }

  # in inheriting class and including
  class InheritingAndIncludingClass < RepresenterClass
    property :location
    include GenreModule
  end

  it { InheritingAndIncludingClass.definitions.keys.must_equal ["title", "location", "genre"] }
end