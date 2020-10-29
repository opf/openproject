require 'test_helper'
require 'integration/runner'
require 'roar/decorator'
require 'roar/client'

class DecoratorClientTest < MiniTest::Spec
  class Crew
    attr_accessor :moniker, :company
  end

  class CrewDecorator < Roar::Decorator
    include Roar::JSON
    include Roar::Hypermedia

    property :moniker, as: :name
    property :company, as: :label

    link(:self) do
      "http://bands/#{represented.moniker}"
    end
  end

  class CrewClient < CrewDecorator
    include Roar::Client
  end

  before do
    @crew = Crew.new
    @client = CrewClient.new(@crew)
  end

  describe 'HttpVerbs integration' do
    describe '#get' do
      it 'updates instance with incoming representation' do
        @client.get(uri: 'http://localhost:4567/bands/slayer', as: 'application/json')
        @crew.moniker.must_equal 'Slayer'
        @crew.company.must_equal 'Canadian Maple'
      end
    end

    describe '#post' do
      it 'creates a new resource with the given values' do
        @crew.moniker = 'Strung Out'
        @crew.company.must_be_nil

        @client.post(uri: 'http://localhost:4567/bands', as: 'application/xml')
        @crew.moniker.must_equal 'STRUNG OUT'
        @crew.company.must_be_nil
      end
    end
  end

  describe '#to_hash' do
    it 'suppresses rendering links' do
      @crew.moniker = 'Silence'
      @client.to_json.must_equal %{{\"name\":\"Silence\",\"links\":[]}}
    end

    # since this is considered dangerous, we test the mutuable options.
    it "adds links: false to options" do
      @client.to_hash(options = {})
      options.must_equal(user_options: {links: false})
    end
  end
end
