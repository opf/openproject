require "helper"

class StiTest < TestCaseClass

  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core
  include FriendlyId::Test::Shared::Slugged

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => [:slugged]
  end

  class Editorialist < Journalist
  end

  def model_class
    Editorialist
  end

  test "friendly_id should accept a base and a hash with single table inheritance" do
    abstract_klass = Class.new(ActiveRecord::Base) do
      def self.table_exists?; false end
      extend FriendlyId
      friendly_id :foo, :use => :slugged, :slug_column => :bar
    end
    klass = Class.new(abstract_klass)
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end

  test "the configuration's model_class should be the class, not the base_class" do
    assert_equal model_class, model_class.friendly_id_config.model_class
  end

  test "friendly_id should accept a block with single table inheritance" do
    abstract_klass = Class.new(ActiveRecord::Base) do
      def self.table_exists?; false end
      extend FriendlyId
      friendly_id :foo do |config|
        config.use :slugged
        config.base = :foo
        config.slug_column = :bar
      end
    end
    klass = Class.new(abstract_klass)
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end

  test "friendly_id slugs should not clash with each other" do
    transaction do
      journalist  = model_class.base_class.create! :name => 'foo bar'
      editoralist = model_class.create! :name => 'foo bar'

      assert_equal 'foo-bar', journalist.slug
      assert_match(/foo-bar-.+/, editoralist.slug)
    end
  end
end

class StiTestWithHistory < StiTest
  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => [:slugged, :history]
  end

  class Editorialist < Journalist
  end

  def model_class
    Editorialist
  end
end


class StiTestWithFinders < TestCaseClass

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => [:slugged, :finders]
  end

  class Editorialist < Journalist
    extend FriendlyId
    friendly_id :name, :use => [:slugged, :finders]
  end

  def model_class
    Editorialist
  end

  test "friendly_id slugs should be looked up from subclass with friendly" do
    transaction do
      editoralist = model_class.create! :name => 'foo bar'
      assert_equal editoralist, model_class.friendly.find(editoralist.slug)
    end
  end

  test "friendly_id slugs should be looked up from subclass" do
    transaction do
      editoralist = model_class.create! :name => 'foo bar'
      assert_equal editoralist, model_class.find(editoralist.slug)
    end
  end

end

class StiTestSubClass < TestCaseClass

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
  end

  class Editorialist < Journalist
    extend FriendlyId
    friendly_id :name, :use => [:slugged, :finders]
  end

  def model_class
    Editorialist
  end

  test "friendly_id slugs can be created and looked up from subclass" do
    transaction do
      editoralist = model_class.create! :name => 'foo bar'
      assert_equal editoralist, model_class.find(editoralist.slug)
    end
  end

end