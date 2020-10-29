# frozen_string_literal: true

shared_examples_for 'versioning' do
  it 'sets the API version' do
    subject.format :txt
    subject.version 'v1', macro_options
    subject.get :hello do
      "Version: #{request.env['api.version']}"
    end
    versioned_get '/hello', 'v1', macro_options
    expect(last_response.body).to eql 'Version: v1'
  end

  it 'adds the prefix before the API version' do
    subject.format :txt
    subject.prefix 'api'
    subject.version 'v1', macro_options
    subject.get :hello do
      "Version: #{request.env['api.version']}"
    end
    versioned_get '/hello', 'v1', macro_options.merge(prefix: 'api')
    expect(last_response.body).to eql 'Version: v1'
  end

  it 'is able to specify version as a nesting' do
    subject.version 'v2', macro_options
    subject.get '/awesome' do
      'Radical'
    end

    subject.version 'v1', macro_options do
      get '/legacy' do
        'Totally'
      end
    end

    versioned_get '/awesome', 'v1', macro_options
    expect(last_response.status).to eql 404

    versioned_get '/awesome', 'v2', macro_options
    expect(last_response.status).to eql 200
    versioned_get '/legacy', 'v1', macro_options
    expect(last_response.status).to eql 200
    versioned_get '/legacy', 'v2', macro_options
    expect(last_response.status).to eql 404
  end

  it 'is able to specify multiple versions' do
    subject.version 'v1', 'v2', macro_options
    subject.get 'awesome' do
      'I exist'
    end

    versioned_get '/awesome', 'v1', macro_options
    expect(last_response.status).to eql 200
    versioned_get '/awesome', 'v2', macro_options
    expect(last_response.status).to eql 200
    versioned_get '/awesome', 'v3', macro_options
    expect(last_response.status).to eql 404
  end

  context 'with different versions for the same endpoint' do
    context 'without a prefix' do
      it 'allows the same endpoint to be implemented' do
        subject.format :txt
        subject.version 'v2', macro_options
        subject.get 'version' do
          request.env['api.version']
        end

        subject.version 'v1', macro_options do
          get 'version' do
            'version ' + request.env['api.version']
          end
        end

        versioned_get '/version', 'v2', macro_options
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('v2')
        versioned_get '/version', 'v1', macro_options
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('version v1')
      end
    end

    context 'with a prefix' do
      it 'allows the same endpoint to be implemented' do
        subject.format :txt
        subject.prefix 'api'
        subject.version 'v2', macro_options
        subject.get 'version' do
          request.env['api.version']
        end

        subject.version 'v1', macro_options do
          get 'version' do
            'version ' + request.env['api.version']
          end
        end

        versioned_get '/version', 'v1', macro_options.merge(prefix: subject.prefix)
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('version v1')

        versioned_get '/version', 'v2', macro_options.merge(prefix: subject.prefix)
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('v2')
      end
    end
  end

  context 'with before block defined within a version block' do
    it 'calls before block that is defined within the version block' do
      subject.format :txt
      subject.prefix 'api'
      subject.version 'v2', macro_options do
        before do
          @output ||= 'v2-'
        end
        get 'version' do
          @output += 'version'
        end
      end

      subject.version 'v1', macro_options do
        before do
          @output ||= 'v1-'
        end
        get 'version' do
          @output += 'version'
        end
      end

      versioned_get '/version', 'v1', macro_options.merge(prefix: subject.prefix)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('v1-version')

      versioned_get '/version', 'v2', macro_options.merge(prefix: subject.prefix)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('v2-version')
    end
  end

  it 'does not overwrite version parameter with API version' do
    subject.format :txt
    subject.version 'v1', macro_options
    subject.params { requires :version }
    subject.get :api_version_with_version_param do
      params[:version]
    end
    versioned_get '/api_version_with_version_param?version=1', 'v1', macro_options
    expect(last_response.body).to eql '1'
  end

  context 'with catch-all' do
    let(:options) { macro_options }
    let(:v1) do
      klass = Class.new(Grape::API)
      klass.version 'v1', options
      klass.get 'version' do
        'v1'
      end
      klass
    end
    let(:v2) do
      klass = Class.new(Grape::API)
      klass.version 'v2', options
      klass.get 'version' do
        'v2'
      end
      klass
    end
    before do
      subject.format :txt

      subject.mount v1
      subject.mount v2

      subject.route :any, '*path' do
        params[:path]
      end
    end

    context 'v1' do
      it 'finds endpoint' do
        versioned_get '/version', 'v1', macro_options
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('v1')
      end

      it 'finds catch all' do
        versioned_get '/whatever', 'v1', macro_options
        expect(last_response.status).to eq(200)
        expect(last_response.body).to end_with 'whatever'
      end
    end

    context 'v2' do
      it 'finds endpoint' do
        versioned_get '/version', 'v2', macro_options
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('v2')
      end

      it 'finds catch all' do
        versioned_get '/whatever', 'v2', macro_options
        expect(last_response.status).to eq(200)
        expect(last_response.body).to end_with 'whatever'
      end
    end
  end
end
