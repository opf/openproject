require 'helper'

class NumericSlugTest < TestCaseClass
  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Article
  end

  test "should generate numeric slugs" do
    transaction do
      record = model_class.create! :name => "123"
      assert_equal "123", record.slug
    end
  end

  test "should find by numeric slug" do
    transaction do
      record = model_class.create! :name => "123"
      assert_equal model_class.friendly.find("123").id, record.id
    end
  end

  test "should exist? by numeric slug" do
    transaction do
      record = model_class.create! :name => "123"
      assert model_class.friendly.exists?("123")
    end
  end
end
