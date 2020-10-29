# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::CoerceValidator do
  subject do
    Class.new(Grape::API)
  end

  def app
    subject
  end

  describe 'coerce' do
    class SecureURIOnly
      def self.parse(value)
        URI.parse(value)
      end

      def self.parsed?(value)
        value.is_a? URI::HTTPS
      end
    end

    context 'i18n' do
      after :each do
        I18n.available_locales = %i[en]
        I18n.locale = :en
        I18n.default_locale = :en
      end

      it 'i18n error on malformed input' do
        I18n.available_locales = %i[en zh-CN]
        I18n.load_path << File.expand_path('../zh-CN.yml', __FILE__)
        I18n.reload!
        I18n.locale = 'zh-CN'.to_sym
        subject.params do
          requires :age, type: Integer
        end
        subject.get '/single' do
          'int works'
        end

        get '/single', age: '43a'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('年龄格式不正确')
      end

      it 'gives an english fallback error when default locale message is blank' do
        I18n.available_locales = %i[en pt-BR]
        I18n.locale = 'pt-BR'.to_sym
        subject.params do
          requires :age, type: Integer
        end
        subject.get '/single' do
          'int works'
        end

        get '/single', age: '43a'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('age is invalid')
      end
    end

    context 'with a custom validation message' do
      it 'errors on malformed input' do
        subject.params do
          requires :int, type: { value: Integer, message: 'type cast is invalid' }
        end
        subject.get '/single' do
          'int works'
        end

        get '/single', int: '43a'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('int type cast is invalid')

        get '/single', int: '43'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('int works')
      end

      context 'on custom coercion rules' do
        before do
          subject.params do
            requires :a, types: { value: [Boolean, String], message: 'type cast is invalid' }, coerce_with: (lambda do |val|
              if val == 'yup'
                true
              elsif val == 'false'
                0
              else
                val
              end
            end)
          end
          subject.get '/' do
            params[:a].class.to_s
          end
        end

        it 'respects :coerce_with' do
          get '/', a: 'yup'

          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('TrueClass')
        end

        it 'still validates type' do
          get '/', a: 'false'
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('a type cast is invalid')
        end

        it 'performs no additional coercion' do
          get '/', a: 'true'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('String')
        end
      end
    end

    it 'error on malformed input' do
      subject.params do
        requires :int, type: Integer
      end
      subject.get '/single' do
        'int works'
      end

      get '/single', int: '43a'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('int is invalid')

      get '/single', int: '43'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('int works')
    end

    it 'error on malformed input (Array)' do
      subject.params do
        requires :ids, type: Array[Integer]
      end
      subject.get '/array' do
        'array int works'
      end

      get 'array', ids: %w[1 2 az]
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('ids is invalid')

      get 'array', ids: %w[1 2 890]
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('array int works')
    end

    context 'coerces' do
      context 'json' do
        let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

        it 'BigDecimal' do
          subject.params do
            requires :bigdecimal, type: BigDecimal
          end
          subject.post '/bigdecimal' do
            "#{params[:bigdecimal].class} #{params[:bigdecimal].to_f}"
          end

          post '/bigdecimal', { bigdecimal: 45.1 }.to_json, headers
          expect(last_response.status).to eq(201)
          expect(last_response.body).to eq('BigDecimal 45.1')
        end

        it 'Boolean' do
          subject.params do
            requires :boolean, type: Boolean
          end
          subject.post '/boolean' do
            params[:boolean]
          end

          post '/boolean', { boolean: 'true' }.to_json, headers
          expect(last_response.status).to eq(201)
          expect(last_response.body).to eq('true')
        end
      end

      it 'BigDecimal' do
        subject.params do
          requires :bigdecimal, coerce: BigDecimal
        end
        subject.get '/bigdecimal' do
          params[:bigdecimal].class
        end

        get '/bigdecimal', bigdecimal: '45'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('BigDecimal')
      end

      it 'Integer' do
        subject.params do
          requires :int, coerce: Integer
        end
        subject.get '/int' do
          params[:int].class
        end

        get '/int', int: '45'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(integer_class_name)
      end

      it 'String' do
        subject.params do
          requires :string, coerce: String
        end
        subject.get '/string' do
          params[:string].class
        end

        get '/string', string: 45
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('String')

        get '/string', string: nil
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('NilClass')
      end

      it 'is a custom type' do
        subject.params do
          requires :uri, coerce: SecureURIOnly
        end
        subject.get '/secure_uri' do
          params[:uri].class
        end

        get 'secure_uri', uri: 'https://www.example.com'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('URI::HTTPS')

        get 'secure_uri', uri: 'http://www.example.com'

        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('uri is invalid')
      end

      context 'Array' do
        it 'Array of Integers' do
          subject.params do
            requires :arry, coerce: Array[Integer]
          end
          subject.get '/array' do
            params[:arry][0].class
          end

          get '/array', arry: %w[1 2 3]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(integer_class_name)
        end

        it 'Array of Bools' do
          subject.params do
            requires :arry, coerce: Array[Grape::API::Boolean]
          end
          subject.get '/array' do
            params[:arry][0].class
          end

          get 'array', arry: [1, 0]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('TrueClass')
        end

        it 'Array of type implementing parse' do
          subject.params do
            requires :uri, type: Array[URI]
          end
          subject.get '/uri_array' do
            params[:uri][0].class
          end
          get 'uri_array', uri: ['http://www.google.com']
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('URI::HTTP')
        end

        it 'Set of type implementing parse' do
          subject.params do
            requires :uri, type: Set[URI]
          end
          subject.get '/uri_array' do
            "#{params[:uri].class},#{params[:uri].first.class},#{params[:uri].size}"
          end
          get 'uri_array', uri: Array.new(2) { 'http://www.example.com' }
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('Set,URI::HTTP,1')
        end

        it 'Array of a custom type' do
          subject.params do
            requires :uri, type: Array[SecureURIOnly]
          end
          subject.get '/secure_uris' do
            params[:uri].first.class
          end
          get 'secure_uris', uri: ['https://www.example.com']
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('URI::HTTPS')
          get 'secure_uris', uri: ['https://www.example.com', 'http://www.example.com']
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('uri is invalid')
        end
      end

      context 'Set' do
        it 'Set of Integers' do
          subject.params do
            requires :set, coerce: Set[Integer]
          end
          subject.get '/set' do
            params[:set].first.class
          end

          get '/set', set: Set.new([1, 2, 3, 4]).to_a
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(integer_class_name)
        end

        it 'Set of Bools' do
          subject.params do
            requires :set, coerce: Set[Grape::API::Boolean]
          end
          subject.get '/set' do
            params[:set].first.class
          end

          get '/set', set: Set.new([1, 0]).to_a
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('TrueClass')
        end
      end

      it 'Boolean' do
        subject.params do
          requires :boolean, type: Boolean
        end
        subject.get '/boolean' do
          params[:boolean].class
        end

        get '/boolean', boolean: 1
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('TrueClass')
      end

      context 'File' do
        let(:file) { Rack::Test::UploadedFile.new(__FILE__) }
        let(:filename) { File.basename(__FILE__).to_s }

        it 'Rack::Multipart::UploadedFile' do
          subject.params do
            requires :file, type: Rack::Multipart::UploadedFile
          end
          subject.post '/upload' do
            params[:file][:filename]
          end

          post '/upload', file: file
          expect(last_response.status).to eq(201)
          expect(last_response.body).to eq(filename)

          post '/upload', file: 'not a file'
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('file is invalid')
        end

        it 'File' do
          subject.params do
            requires :file, coerce: File
          end
          subject.post '/upload' do
            params[:file][:filename]
          end

          post '/upload', file: file
          expect(last_response.status).to eq(201)
          expect(last_response.body).to eq(filename)

          post '/upload', file: 'not a file'
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('file is invalid')

          post '/upload', file: { filename: 'fake file', tempfile: '/etc/passwd' }
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('file is invalid')
        end

        it 'collection' do
          subject.params do
            requires :files, type: Array[File]
          end
          subject.post '/upload' do
            params[:files].first[:filename]
          end

          post '/upload', files: [file]
          expect(last_response.status).to eq(201)
          expect(last_response.body).to eq(filename)
        end
      end

      it 'Nests integers' do
        subject.params do
          requires :integers, type: Hash do
            requires :int, coerce: Integer
          end
        end
        subject.get '/int' do
          params[:integers][:int].class
        end

        get '/int', integers: { int: '45' }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(integer_class_name)
      end

      context 'nil values' do
        context 'primitive types' do
          Grape::Validations::Types::PRIMITIVES.each do |type|
            it 'respects the nil value' do
              subject.params do
                requires :param, type: type
              end
              subject.get '/nil_value' do
                params[:param].class
              end

              get '/nil_value', param: nil
              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq('NilClass')
            end
          end
        end

        context 'structures types' do
          Grape::Validations::Types::STRUCTURES.each do |type|
            it 'respects the nil value' do
              subject.params do
                requires :param, type: type
              end
              subject.get '/nil_value' do
                params[:param].class
              end

              get '/nil_value', param: nil
              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq('NilClass')
            end
          end
        end

        context 'special types' do
          Grape::Validations::Types::SPECIAL.each_key do |type|
            it 'respects the nil value' do
              subject.params do
                requires :param, type: type
              end
              subject.get '/nil_value' do
                params[:param].class
              end

              get '/nil_value', param: nil
              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq('NilClass')
            end
          end

          context 'variant-member-type collections' do
            [
              Array[Integer, String],
              [Integer, String, Array[Integer, String]]
            ].each do |type|
              it 'respects the nil value' do
                subject.params do
                  requires :param, type: type
                end
                subject.get '/nil_value' do
                  params[:param].class
                end

                get '/nil_value', param: nil
                expect(last_response.status).to eq(200)
                expect(last_response.body).to eq('NilClass')
              end
            end
          end
        end
      end
    end

    context 'using coerce_with' do
      it 'parses parameters with Array type' do
        subject.params do
          requires :values, type: Array, coerce_with: ->(val) { val.split(/\s+/).map(&:to_i) }
        end
        subject.get '/ints' do
          params[:values]
        end

        get '/ints', values: '1 2 3 4'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq([1, 2, 3, 4])

        get '/ints', values: 'a b c d'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq([0, 0, 0, 0])
      end

      it 'parses parameters with Array[String] type' do
        subject.params do
          requires :values, type: Array[String], coerce_with: ->(val) { val.split(/\s+/) }
        end
        subject.get '/strings' do
          params[:values]
        end

        get '/strings', values: '1 2 3 4'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq(%w[1 2 3 4])

        get '/strings', values: 'a b c d'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq(%w[a b c d])
      end

      it 'parses parameters with Array[Integer] type' do
        subject.params do
          requires :values, type: Array[Integer], coerce_with: ->(val) { val.split(/\s+/).map(&:to_i) }
        end
        subject.get '/ints' do
          params[:values]
        end

        get '/ints', values: '1 2 3 4'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq([1, 2, 3, 4])

        get '/ints', values: 'a b c d'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq([0, 0, 0, 0])
      end

      it 'parses parameters even if type is valid' do
        subject.params do
          requires :values, type: Array, coerce_with: ->(array) { array.map { |val| val.to_i + 1 } }
        end
        subject.get '/ints' do
          params[:values]
        end

        get '/ints', values: [1, 2, 3, 4]
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq([2, 3, 4, 5])

        get '/ints', values: %w[a b c d]
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq([1, 1, 1, 1])
      end

      it 'uses parse where available' do
        subject.params do
          requires :ints, type: Array, coerce_with: JSON do
            requires :i, type: Integer
            requires :j
          end
        end
        subject.get '/ints' do
          ints = params[:ints].first
          'coercion works' if ints[:i] == 1 && ints[:j] == '2'
        end

        get '/ints', ints: [{ i: 1, j: '2' }]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('ints is invalid')

        get '/ints', ints: '{"i":1,"j":"2"}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('ints is invalid')

        get '/ints', ints: '[{"i":"1","j":"2"}]'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('coercion works')
      end

      it 'accepts any callable' do
        subject.params do
          requires :ints, type: Hash, coerce_with: JSON.method(:parse) do
            requires :int, type: Integer, coerce_with: ->(val) { val == 'three' ? 3 : val }
          end
        end
        subject.get '/ints' do
          params[:ints][:int]
        end

        get '/ints', ints: '{"int":"3"}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('ints[int] is invalid')

        get '/ints', ints: '{"int":"three"}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('3')

        get '/ints', ints: '{"int":3}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('3')
      end

      context 'Integer type and coerce_with potentially returning nil' do
        before do
          subject.params do
            requires :int, type: Integer, coerce_with: (lambda do |val|
              if val == '0'
                nil
              elsif val.match?(/^-?\d+$/)
                val.to_i
              else
                val
              end
            end)
          end
          subject.get '/' do
            params[:int].class.to_s
          end
        end

        it 'accepts value that coerces to nil' do
          get '/', int: '0'

          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('NilClass')
        end

        it 'coerces to Integer' do
          get '/', int: '1'

          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('Integer')
        end

        it 'returns invalid value if coercion returns a wrong type' do
          get '/', int: 'lol'

          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('int is invalid')
        end
      end

      it 'must be supplied with :type or :coerce' do
        expect do
          subject.params do
            requires :ints, coerce_with: JSON
          end
        end.to raise_error(ArgumentError)
      end
    end

    context 'first-class JSON' do
      it 'parses objects, hashes, and arrays' do
        subject.params do
          requires :splines, type: JSON do
            requires :x, type: Integer, values: [1, 2, 3]
            optional :ints, type: Array[Integer]
            optional :obj, type: Hash do
              optional :y
            end
          end
        end
        subject.get '/' do
          if params[:splines].is_a? Hash
            params[:splines][:obj][:y]
          elsif params[:splines].any? { |s| s.key? :obj }
            'arrays work'
          end
        end

        get '/', splines: '{"x":1,"ints":[1,2,3],"obj":{"y":"woof"}}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('woof')

        get '/', splines: { x: 1, ints: [1, 2, 3], obj: { y: 'woof' } }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('woof')

        get '/', splines: '[{"x":2,"ints":[]},{"x":3,"ints":[4],"obj":{"y":"quack"}}]'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('arrays work')

        get '/', splines: [{ x: 2, ints: [5] }, { x: 3, ints: [4], obj: { y: 'quack' } }]
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('arrays work')

        get '/', splines: '{"x":4,"ints":[2]}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')

        get '/', splines: { x: 4, ints: [2] }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')

        get '/', splines: '[{"x":1,"ints":[]},{"x":4,"ints":[]}]'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')

        get '/', splines: [{ x: 1, ints: [5] }, { x: 4, ints: [6] }]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')
      end

      it 'works when declared optional' do
        subject.params do
          optional :splines, type: JSON do
            requires :x, type: Integer, values: [1, 2, 3]
            optional :ints, type: Array[Integer]
            optional :obj, type: Hash do
              optional :y
            end
          end
        end
        subject.get '/' do
          if params[:splines].is_a? Hash
            params[:splines][:obj][:y]
          elsif params[:splines].any? { |s| s.key? :obj }
            'arrays work'
          end
        end

        get '/', splines: '{"x":1,"ints":[1,2,3],"obj":{"y":"woof"}}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('woof')

        get '/', splines: '[{"x":2,"ints":[]},{"x":3,"ints":[4],"obj":{"y":"quack"}}]'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('arrays work')

        get '/', splines: '{"x":4,"ints":[2]}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')

        get '/', splines: '[{"x":1,"ints":[]},{"x":4,"ints":[]}]'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')
      end

      it 'accepts Array[JSON] shorthand' do
        subject.params do
          requires :splines, type: Array[JSON] do
            requires :x, type: Integer, values: [1, 2, 3]
            requires :y
          end
        end
        subject.get '/' do
          params[:splines].first[:y].class.to_s
          spline = params[:splines].first
          "#{spline[:x].class}.#{spline[:y].class}"
        end

        get '/', splines: '{"x":"1","y":"woof"}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("#{integer_class_name}.String")

        get '/', splines: '[{"x":1,"y":2},{"x":1,"y":"quack"}]'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("#{integer_class_name}.#{integer_class_name}")

        get '/', splines: '{"x":"4","y":"woof"}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')

        get '/', splines: '[{"x":"4","y":"woof"}]'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')
      end

      it "doesn't make sense using coerce_with" do
        expect do
          subject.params do
            requires :bad, type: JSON, coerce_with: JSON do
              requires :x
            end
          end
        end.to raise_error(ArgumentError)

        expect do
          subject.params do
            requires :bad, type: Array[JSON], coerce_with: JSON do
              requires :x
            end
          end
        end.to raise_error(ArgumentError)
      end
    end

    context 'multiple types' do
      Boolean = Grape::API::Boolean

      it 'coerces to first possible type' do
        subject.params do
          requires :a, types: [Boolean, Integer, String]
        end
        subject.get '/' do
          params[:a].class.to_s
        end

        get '/', a: 'true'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('TrueClass')

        get '/', a: '5'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(integer_class_name)

        get '/', a: 'anything else'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('String')
      end

      it 'fails when no coercion is possible' do
        subject.params do
          requires :a, types: [Boolean, Integer]
        end
        subject.get '/' do
          params[:a].class.to_s
        end

        get '/', a: true
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('TrueClass')

        get '/', a: 'not good'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('a is invalid')
      end

      context 'for primitive collections' do
        before do
          subject.params do
            optional :a, types: [String, Array[String]]
            optional :b, types: [Array[Integer], Array[String]]
            optional :c, type: Array[Integer, String]
            optional :d, types: [Integer, String, Set[Integer, String]]
          end
          subject.get '/' do
            (
              params[:a] ||
              params[:b] ||
              params[:c] ||
              params[:d]
            ).inspect
          end
        end

        it 'allows singular form declaration' do
          get '/', a: 'one way'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('"one way"')

          get '/', a: %w[the other]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('["the", "other"]')

          get '/', a: { a: 1, b: 2 }
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('a is invalid')

          get '/', a: [1, 2, 3]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('["1", "2", "3"]')
        end

        it 'allows multiple collection types' do
          get '/', b: [1, 2, 3]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('[1, 2, 3]')

          get '/', b: %w[1 2 3]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('[1, 2, 3]')

          get '/', b: [1, true, 'three']
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('["1", "true", "three"]')
        end

        it 'allows collections with multiple types' do
          get '/', c: [1, '2', true, 'three']
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('[1, 2, "true", "three"]')

          get '/', d: '1'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('1')

          get '/', d: 'one'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('"one"')

          get '/', d: %w[1 two]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('#<Set: {1, "two"}>')
        end
      end

      context 'when params is Hashie::Mash' do
        context 'for primitive collections' do
          before do
            subject.params do
              build_with Grape::Extensions::Hashie::Mash::ParamBuilder
              optional :a, types: [String, Array[String]]
              optional :b, types: [Array[Integer], Array[String]]
              optional :c, type: Array[Integer, String]
              optional :d, types: [Integer, String, Set[Integer, String]]
            end
            subject.get '/' do
              (
                params.a ||
                params.b ||
                params.c ||
                params.d
              ).inspect
            end
          end

          it 'allows singular form declaration' do
            get '/', a: 'one way'
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('"one way"')

            get '/', a: %w[the other]
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('#<Hashie::Array ["the", "other"]>')

            get '/', a: { a: 1, b: 2 }
            expect(last_response.status).to eq(400)
            expect(last_response.body).to eq('a is invalid')

            get '/', a: [1, 2, 3]
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('#<Hashie::Array ["1", "2", "3"]>')
          end

          it 'allows multiple collection types' do
            get '/', b: [1, 2, 3]
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('#<Hashie::Array [1, 2, 3]>')

            get '/', b: %w[1 2 3]
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('#<Hashie::Array [1, 2, 3]>')

            get '/', b: [1, true, 'three']
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('#<Hashie::Array ["1", "true", "three"]>')
          end

          it 'allows collections with multiple types' do
            get '/', c: [1, '2', true, 'three']
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('#<Hashie::Array [1, 2, "true", "three"]>')

            get '/', d: '1'
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('1')

            get '/', d: 'one'
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('"one"')

            get '/', d: %w[1 two]
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq('#<Set: {1, "two"}>')
          end
        end
      end

      context 'custom coercion rules' do
        before do
          subject.params do
            requires :a, types: [Boolean, String], coerce_with: (lambda do |val|
              if val == 'yup'
                true
              elsif val == 'false'
                0
              else
                val
              end
            end)
          end
          subject.get '/' do
            params[:a].class.to_s
          end
        end

        it 'respects :coerce_with' do
          get '/', a: 'yup'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('TrueClass')
        end

        it 'still validates type' do
          get '/', a: 'false'
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('a is invalid')
        end

        it 'performs no additional coercion' do
          get '/', a: 'true'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('String')
        end
      end

      it 'may not be supplied together with a single type' do
        expect do
          subject.params do
            requires :a, type: Integer, types: [Integer, String]
          end
        end.to raise_exception ArgumentError
      end
    end

    context 'converter' do
      it 'does not build a coercer multiple times' do
        subject.params do
          requires :something, type: Array[String]
        end
        subject.get do
        end

        expect(Grape::Validations::Types::ArrayCoercer).to(
          receive(:new).at_most(:once).and_call_original
        )

        10.times { get '/' }
      end
    end
  end
end
