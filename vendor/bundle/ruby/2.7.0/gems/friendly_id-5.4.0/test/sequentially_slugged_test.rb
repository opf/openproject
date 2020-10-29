require 'helper'

class Article < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :sequentially_slugged
end

class SequentiallySluggedTest < TestCaseClass
  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Article
  end

  test "should generate numerically sequential slugs" do
    transaction do
      records = 12.times.map { model_class.create! :name => "Some news" }
      assert_equal "some-news", records[0].slug
      (1...12).each {|i| assert_equal "some-news-#{i + 1}", records[i].slug}
    end
  end

  test "should cope when slugs are missing from the sequence" do
    transaction do
      record_1 = model_class.create!(:name => 'A thing')
      record_2 = model_class.create!(:name => 'A thing')
      record_3 = model_class.create!(:name => 'A thing')

      assert_equal 'a-thing', record_1.slug
      assert_equal 'a-thing-2', record_2.slug
      assert_equal 'a-thing-3', record_3.slug

      record_2.destroy

      record_4 = model_class.create!(:name => 'A thing')

      assert_equal 'a-thing-4', record_4.slug
    end
  end

  test "should cope with strange column names" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "journalists"
      extend FriendlyId
      friendly_id :name, :use => :sequentially_slugged, :slug_column => "strange name"
    end

    transaction do
      record_1 = model_class.create! name: "Julian Assange"
      record_2 = model_class.create! name: "Julian Assange"

      assert_equal 'julian-assange', record_1.attributes["strange name"]
      assert_equal 'julian-assange-2', record_2.attributes["strange name"]
    end
  end

  test "should correctly sequence slugs that end in a number" do
    transaction do
      record1 = model_class.create! :name => "Peugeuot 206"
      assert_equal "peugeuot-206", record1.slug
      record2 = model_class.create! :name => "Peugeuot 206"
      assert_equal "peugeuot-206-2", record2.slug
    end
  end

  test "should correctly sequence slugs that begin with a number" do
    transaction do
      record1 = model_class.create! :name => "2010 to 2015 Records"
      assert_equal "2010-to-2015-records", record1.slug
      record2 = model_class.create! :name => "2010 to 2015 Records"
      assert_equal "2010-to-2015-records-2", record2.slug
    end
  end

  test "should sequence with a custom sequence separator" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "novelists"
      extend FriendlyId
      friendly_id :name, :use => :sequentially_slugged, :sequence_separator => ':'
    end

    transaction do
      record_1 = model_class.create! name: "Julian Barnes"
      record_2 = model_class.create! name: "Julian Barnes"

      assert_equal 'julian-barnes', record_1.slug
      assert_equal 'julian-barnes:2', record_2.slug
    end
  end

  test "should not generate a slug when canidates set is empty" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "cities"
      extend FriendlyId
      friendly_id :slug_candidates, :use => [ :sequentially_slugged ]

      def slug_candidates
        [name, [name, code]]
      end
    end
    transaction do
      record = model_class.create!(:name => nil, :code => nil)
      assert_nil record.slug
    end
  end

  test "should not generate a slug when the sluggable attribute is blank" do
    record = model_class.create!(:name => '')
    assert_nil record.slug
  end
end

class SequentiallySluggedTestWithHistory < TestCaseClass
  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  class Article < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => [:sequentially_slugged, :history]
  end

  def model_class
    Article
  end

  test "should work with regeneration with history when slug already exists" do
    transaction do
      record1 = model_class.create! :name => "Test name"
      record2 = model_class.create! :name => "Another test name"
      assert_equal 'test-name', record1.slug
      assert_equal 'another-test-name', record2.slug

      record2.name = "Test name"
      record2.slug = nil
      record2.save!
      assert_equal 'test-name-2', record2.slug
    end
  end

  test "should work with regeneration with history when 2 slugs already exists and the second is changed" do
    transaction do
      record1 = model_class.create! :name => "Test name"
      record2 = model_class.create! :name => "Test name"
      record3 = model_class.create! :name => "Another test name"
      assert_equal 'test-name', record1.slug
      assert_equal 'test-name-2', record2.slug
      assert_equal 'another-test-name', record3.slug

      record2.name = "One more test name"
      record2.slug = nil
      record2.save!
      assert_equal 'one-more-test-name', record2.slug

      record3.name = "Test name"
      record3.slug = nil
      record3.save!
      assert_equal 'test-name-3', record3.slug
    end
  end
end

class City < ActiveRecord::Base
  has_many :restaurants
end

class Restaurant < ActiveRecord::Base
  extend FriendlyId
  belongs_to :city
  friendly_id :name, :use => [:sequentially_slugged, :scoped, :history], :scope => :city
end

class SequentiallySluggedTestWithScopedHistory < TestCaseClass
  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Restaurant
  end

  test "should work with regeneration with scoped history" do
    transaction do
      city1 = City.create!
      city2 = City.create!
      record1 = model_class.create! :name => "Test name", :city => city1
      record2 = model_class.create! :name => "Test name", :city => city1

      assert_equal 'test-name', record1.slug
      assert_equal 'test-name-2', record2.slug

      record2.name = 'Another test name'
      record2.slug = nil
      record2.save!

      record3 = model_class.create! :name => "Test name", :city => city1
      assert_equal 'test-name-3', record3.slug
    end
  end
end
