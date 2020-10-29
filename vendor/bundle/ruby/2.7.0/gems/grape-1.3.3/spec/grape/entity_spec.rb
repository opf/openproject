# frozen_string_literal: true

require 'spec_helper'
require 'grape_entity'

describe Grape::Entity do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe '#present' do
    it 'sets the object as the body if no options are provided' do
      inner_body = nil
      subject.get '/example' do
        present(abc: 'def')
        inner_body = body
      end
      get '/example'
      expect(inner_body).to eql(abc: 'def')
    end

    it 'calls through to the provided entity class if one is given' do
      entity_mock = Object.new
      allow(entity_mock).to receive(:represent)

      subject.get '/example' do
        present Object.new, with: entity_mock
      end
      get '/example'
    end

    it 'pulls a representation from the class options if it exists' do
      entity = Class.new(Grape::Entity)
      allow(entity).to receive(:represent).and_return('Hiya')

      subject.represent Object, with: entity
      subject.get '/example' do
        present Object.new
      end
      get '/example'
      expect(last_response.body).to eq('Hiya')
    end

    it 'pulls a representation from the class options if the presented object is a collection of objects' do
      entity = Class.new(Grape::Entity)
      allow(entity).to receive(:represent).and_return('Hiya')

      module EntitySpec
        class TestObject
        end

        class FakeCollection
          def first
            TestObject.new
          end
        end
      end

      subject.represent EntitySpec::TestObject, with: entity
      subject.get '/example' do
        present [EntitySpec::TestObject.new]
      end

      subject.get '/example2' do
        present EntitySpec::FakeCollection.new
      end

      get '/example'
      expect(last_response.body).to eq('Hiya')

      get '/example2'
      expect(last_response.body).to eq('Hiya')
    end

    it 'pulls a representation from the class ancestor if it exists' do
      entity = Class.new(Grape::Entity)
      allow(entity).to receive(:represent).and_return('Hiya')

      subclass = Class.new(Object)

      subject.represent Object, with: entity
      subject.get '/example' do
        present subclass.new
      end
      get '/example'
      expect(last_response.body).to eq('Hiya')
    end

    it 'automatically uses Klass::Entity if that exists' do
      some_model = Class.new
      entity = Class.new(Grape::Entity)
      allow(entity).to receive(:represent).and_return('Auto-detect!')

      some_model.const_set :Entity, entity

      subject.get '/example' do
        present some_model.new
      end
      get '/example'
      expect(last_response.body).to eq('Auto-detect!')
    end

    it 'automatically uses Klass::Entity based on the first object in the collection being presented' do
      some_model = Class.new
      entity = Class.new(Grape::Entity)
      allow(entity).to receive(:represent).and_return('Auto-detect!')

      some_model.const_set :Entity, entity

      subject.get '/example' do
        present [some_model.new]
      end
      get '/example'
      expect(last_response.body).to eq('Auto-detect!')
    end

    it 'does not run autodetection for Entity when explicitely provided' do
      entity = Class.new(Grape::Entity)
      some_array = []

      subject.get '/example' do
        present some_array, with: entity
      end

      expect(some_array).not_to receive(:first)
      get '/example'
    end

    it 'does not use #first method on ActiveRecord::Relation to prevent needless sql query' do
      entity = Class.new(Grape::Entity)
      some_relation = Class.new
      some_model = Class.new

      allow(entity).to receive(:represent).and_return('Auto-detect!')
      allow(some_relation).to receive(:first)
      allow(some_relation).to receive(:klass).and_return(some_model)

      some_model.const_set :Entity, entity

      subject.get '/example' do
        present some_relation
      end

      expect(some_relation).not_to receive(:first)
      get '/example'
      expect(last_response.body).to eq('Auto-detect!')
    end

    it 'autodetection does not use Entity if it is not a presenter' do
      some_model = Class.new
      entity = Class.new

      some_model.class.const_set :Entity, entity

      subject.get '/example' do
        present some_model
      end
      get '/example'
      expect(entity).not_to receive(:represent)
    end

    it 'adds a root key to the output if one is given' do
      inner_body = nil
      subject.get '/example' do
        present({ abc: 'def' }, root: :root)
        inner_body = body
      end
      get '/example'
      expect(inner_body).to eql(root: { abc: 'def' })
    end

    %i[json serializable_hash].each do |format|
      it "presents with #{format}" do
        entity = Class.new(Grape::Entity)
        entity.root 'examples', 'example'
        entity.expose :id

        subject.format format
        subject.get '/example' do
          c = Class.new do
            attr_reader :id
            def initialize(id)
              @id = id
            end
          end
          present c.new(1), with: entity
        end

        get '/example'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('{"example":{"id":1}}')
      end

      it "presents with #{format} collection" do
        entity = Class.new(Grape::Entity)
        entity.root 'examples', 'example'
        entity.expose :id

        subject.format format
        subject.get '/examples' do
          c = Class.new do
            attr_reader :id
            def initialize(id)
              @id = id
            end
          end
          examples = [c.new(1), c.new(2)]
          present examples, with: entity
        end

        get '/examples'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('{"examples":[{"id":1},{"id":2}]}')
      end
    end

    it 'presents with xml' do
      entity = Class.new(Grape::Entity)
      entity.root 'examples', 'example'
      entity.expose :name

      subject.format :xml

      subject.get '/example' do
        c = Class.new do
          attr_reader :name
          def initialize(args)
            @name = args[:name] || 'no name set'
          end
        end
        present c.new(name: 'johnnyiller'), with: entity
      end
      get '/example'
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-type']).to eq('application/xml')
      expect(last_response.body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <example>
    <name>johnnyiller</name>
  </example>
</hash>
XML
    end

    it 'presents with json' do
      entity = Class.new(Grape::Entity)
      entity.root 'examples', 'example'
      entity.expose :name

      subject.format :json

      subject.get '/example' do
        c = Class.new do
          attr_reader :name
          def initialize(args)
            @name = args[:name] || 'no name set'
          end
        end
        present c.new(name: 'johnnyiller'), with: entity
      end
      get '/example'
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-type']).to eq('application/json')
      expect(last_response.body).to eq('{"example":{"name":"johnnyiller"}}')
    end

    it 'presents with jsonp utilising Rack::JSONP' do
      # Include JSONP middleware
      subject.use Rack::JSONP

      entity = Class.new(Grape::Entity)
      entity.root 'examples', 'example'
      entity.expose :name

      # Rack::JSONP expects a standard JSON response in UTF-8 format
      subject.format :json
      subject.formatter :json, lambda { |object, _|
        object.to_json.encode('utf-8')
      }

      subject.get '/example' do
        c = Class.new do
          attr_reader :name
          def initialize(args)
            @name = args[:name] || 'no name set'
          end
        end

        present c.new(name: 'johnnyiller'), with: entity
      end

      get '/example?callback=abcDef'
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-type']).to eq('application/javascript')
      expect(last_response.body).to include 'abcDef({"example":{"name":"johnnyiller"}})'
    end

    context 'present with multiple entities' do
      it 'present with multiple entities using optional symbol' do
        user = Class.new do
          attr_reader :name
          def initialize(args)
            @name = args[:name] || 'no name set'
          end
        end
        user1 = user.new(name: 'user1')
        user2 = user.new(name: 'user2')

        entity = Class.new(Grape::Entity)
        entity.expose :name

        subject.format :json
        subject.get '/example' do
          present :page, 1
          present :user1, user1, with: entity
          present :user2, user2, with: entity
        end
        get '/example'
        expect_response_json = {
          'page'  => 1,
          'user1' => { 'name' => 'user1' },
          'user2' => { 'name' => 'user2' }
        }
        expect(JSON(last_response.body)).to eq(expect_response_json)
      end
    end
  end
end
