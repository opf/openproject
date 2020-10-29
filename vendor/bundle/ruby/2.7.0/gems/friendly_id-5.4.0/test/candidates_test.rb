require "helper"

class CandidatesTest < TestCaseClass

  include FriendlyId::Test

  class City < ActiveRecord::Base
    extend FriendlyId
    friendly_id :slug_candidates, use: :slugged
    alias_attribute :slug_candidates, :name
  end

  def model_class
    City
  end

  def with_instances_of(klass = model_class, &block)
    transaction do
      city1 = klass.create! :name => "New York", :code => "JFK"
      city2 = klass.create! :name => "New York", :code => "EWR"
      yield city1, city2
    end
  end
  alias_method :with_instances, :with_instances_of

  test "resolves conflict with candidate" do
    with_instances do |city1, city2|
      assert_equal "new-york", city1.slug
      assert_match(/\Anew-york-([a-z0-9]+\-){4}[a-z0-9]+\z/, city2.slug)
    end
  end

  test "accepts candidate as symbol" do
    klass = Class.new model_class do
      def slug_candidates
        :name
      end
    end
    with_instances_of klass do |_, city|
      assert_match(/\Anew-york-([a-z0-9]+\-){4}[a-z0-9]+\z/, city.slug)
    end
  end

  test "accepts multiple candidates" do
    klass = Class.new model_class do
      def slug_candidates
        [name, code]
      end
    end
    with_instances_of klass do |_, city|
      assert_equal "ewr", city.slug
    end
  end

  test "ignores blank candidate" do
    klass = Class.new model_class do
      def slug_candidates
        [name, ""]
      end
    end
    with_instances_of klass do |_, city|
      assert_match(/\Anew-york-([a-z0-9]+\-){4}[a-z0-9]+\z/, city.slug)
    end
  end

  test "ignores nil candidate" do
    klass = Class.new model_class do
      def slug_candidates
        [name, nil]
      end
    end
    with_instances_of klass do |_, city|
      assert_match(/\Anew-york-([a-z0-9]+\-){4}[a-z0-9]+\z/, city.slug)
    end
  end

  test "accepts candidate with nested array" do
    klass = Class.new model_class do
      def slug_candidates
        [name, [name, code]]
      end
    end
    with_instances_of klass do |_, city|
      assert_equal "new-york-ewr", city.slug
    end
  end

  test "accepts candidate with lambda" do
    klass = Class.new City do
      def slug_candidates
        [name, [name, ->{ rand 1000 }]]
      end
    end
    with_instances_of klass do |_, city|
      assert_match(/\Anew-york-\d{,3}\z/, city.friendly_id)
    end
  end

  test "accepts candidate with object" do
    klass = Class.new City do
      class Airport
        def initialize(code)
          @code = code
        end
        attr_reader :code
        alias_method :to_s, :code
      end
      def slug_candidates
        [name, [name, Airport.new(code)]]
      end
    end
    with_instances_of klass do |_, city|
      assert_equal "new-york-ewr", city.friendly_id
    end
  end

  test "allows to iterate through candidates without passing block" do
    klass = Class.new model_class do
      def slug_candidates
        :name
      end
    end
    with_instances_of klass do |_, city|
      candidates = FriendlyId::Candidates.new(city, city.slug_candidates)
      assert_equal candidates.each, ['new-york']
    end
  end

  test "iterates through candidates with passed block" do
    klass = Class.new model_class do
      def slug_candidates
        :name
      end
    end
    with_instances_of klass do |_, city|
      collected_candidates = []
      candidates = FriendlyId::Candidates.new(city, city.slug_candidates)
      candidates.each { |candidate| collected_candidates << candidate }
      assert_equal collected_candidates, ['new-york']
    end
  end

end
