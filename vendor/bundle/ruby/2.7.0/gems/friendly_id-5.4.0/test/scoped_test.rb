require "helper"

class Novelist < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

class Novel < ActiveRecord::Base
  extend FriendlyId
  belongs_to :novelist
  belongs_to :publisher
  friendly_id :name, :use => :scoped, :scope => [:publisher, :novelist]

  def should_generate_new_friendly_id?
    new_record? || super
  end
end

class Publisher < ActiveRecord::Base
  has_many :novels
end

class ScopedTest < TestCaseClass

  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Novel
  end

  test "should detect scope column from belongs_to relation" do
    assert_equal ["publisher_id", "novelist_id"], Novel.friendly_id_config.scope_columns
  end

  test "should detect scope column from explicit column name" do
    model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend FriendlyId
      friendly_id :empty, :use => :scoped, :scope => :dummy
    end
    assert_equal ["dummy"], model_class.friendly_id_config.scope_columns
  end

  test "should allow duplicate slugs outside scope" do
    transaction do
      novel1 = Novel.create! :name => "a", :novelist => Novelist.create!(:name => "a")
      novel2 = Novel.create! :name => "a", :novelist => Novelist.create!(:name => "b")
      assert_equal novel1.friendly_id, novel2.friendly_id
    end
  end

  test "should not allow duplicate slugs inside scope" do
    with_instance_of Novelist do |novelist|
      novel1 = Novel.create! :name => "a", :novelist => novelist
      novel2 = Novel.create! :name => "a", :novelist => novelist
      assert novel1.friendly_id != novel2.friendly_id
    end
  end

  test "should apply scope with multiple columns" do
    transaction do
      novelist = Novelist.create! :name => "a"
      publisher = Publisher.create! :name => "b"
      novel1 = Novel.create! :name => "c", :novelist => novelist, :publisher => publisher
      novel2 = Novel.create! :name => "c", :novelist => novelist, :publisher => Publisher.create(:name => "d")
      novel3 = Novel.create! :name => "c", :novelist => Novelist.create(:name => "e"), :publisher => publisher
      novel4 = Novel.create! :name => "c", :novelist => novelist, :publisher => publisher
      assert_equal novel1.friendly_id, novel2.friendly_id
      assert_equal novel2.friendly_id, novel3.friendly_id
      assert novel3.friendly_id != novel4.friendly_id
    end
  end

  test 'should allow a record to reuse its own slug' do
    with_instance_of(model_class) do |record|
      old_id = record.friendly_id
      record.slug = nil
      record.save!
      assert_equal old_id, record.friendly_id
    end
  end

  test "should generate new slug when scope changes" do
    transaction do
      novelist = Novelist.create! :name => "a"
      publisher = Publisher.create! :name => "b"
      novel1 = Novel.create! :name => "c", :novelist => novelist, :publisher => publisher
      novel2 = Novel.create! :name => "c", :novelist => novelist, :publisher => Publisher.create(:name => "d")
      assert_equal novel1.friendly_id, novel2.friendly_id
      novel2.publisher = publisher
      novel2.save!
      assert novel2.friendly_id != novel1.friendly_id
    end
  end

end
