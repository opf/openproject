# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module InsideRouteSpec
      class Dummy
        include Grape::DSL::InsideRoute

        attr_reader :env, :request, :new_settings

        def initialize
          @env = {}
          @header = {}
          @new_settings = { namespace_inheritable: {}, namespace_stackable: {} }
        end
      end
    end
  end
end

describe Grape::Endpoint do
  subject { Grape::DSL::InsideRouteSpec::Dummy.new }

  describe '#version' do
    it 'defaults to nil' do
      expect(subject.version).to be nil
    end

    it 'returns env[api.version]' do
      subject.env['api.version'] = 'dummy'
      expect(subject.version).to eq 'dummy'
    end
  end

  describe '#error!' do
    it 'throws :error' do
      expect { subject.error! 'Not Found', 404 }.to throw_symbol(:error)
    end

    describe 'thrown' do
      before do
        catch(:error) { subject.error! 'Not Found', 404 }
      end
      it 'sets status' do
        expect(subject.status).to eq 404
      end
    end

    describe 'default_error_status' do
      before do
        subject.namespace_inheritable(:default_error_status, 500)
        catch(:error) { subject.error! 'Unknown' }
      end
      it 'sets status to default_error_status' do
        expect(subject.status).to eq 500
      end
    end

    # self.status(status || settings[:default_error_status])
    # throw :error, message: message, status: self.status, headers: headers
  end

  describe '#redirect' do
    describe 'default' do
      before do
        subject.redirect '/'
      end

      it 'sets status to 302' do
        expect(subject.status).to eq 302
      end

      it 'sets location header' do
        expect(subject.header['Location']).to eq '/'
      end
    end

    describe 'permanent' do
      before do
        subject.redirect '/', permanent: true
      end

      it 'sets status to 301' do
        expect(subject.status).to eq 301
      end

      it 'sets location header' do
        expect(subject.header['Location']).to eq '/'
      end
    end
  end

  describe '#status' do
    %w[GET PUT OPTIONS].each do |method|
      it 'defaults to 200 on GET' do
        request = Grape::Request.new(Rack::MockRequest.env_for('/', method: method))
        expect(subject).to receive(:request).and_return(request)
        expect(subject.status).to eq 200
      end
    end

    it 'defaults to 201 on POST' do
      request = Grape::Request.new(Rack::MockRequest.env_for('/', method: 'POST'))
      expect(subject).to receive(:request).and_return(request)
      expect(subject.status).to eq 201
    end

    it 'defaults to 204 on DELETE' do
      request = Grape::Request.new(Rack::MockRequest.env_for('/', method: 'DELETE'))
      expect(subject).to receive(:request).and_return(request)
      expect(subject.status).to eq 204
    end

    it 'defaults to 200 on DELETE with a body present' do
      request = Grape::Request.new(Rack::MockRequest.env_for('/', method: 'DELETE'))
      subject.body 'content here'
      expect(subject).to receive(:request).and_return(request)
      expect(subject.status).to eq 200
    end

    it 'returns status set' do
      subject.status 501
      expect(subject.status).to eq 501
    end

    it 'accepts symbol for status' do
      subject.status :see_other
      expect(subject.status).to eq 303
    end

    it 'raises error if unknow symbol is passed' do
      expect { subject.status :foo_bar }
        .to raise_error(ArgumentError, 'Status code :foo_bar is invalid.')
    end

    it 'accepts unknown Integer status codes' do
      expect { subject.status 210 }.to_not raise_error
    end

    it 'raises error if status is not a integer or symbol' do
      expect { subject.status Object.new }
        .to raise_error(ArgumentError, 'Status code must be Integer or Symbol.')
    end
  end

  describe '#return_no_content' do
    it 'sets the status code and body' do
      subject.return_no_content
      expect(subject.status).to eq 204
      expect(subject.body).to eq ''
    end
  end

  describe '#content_type' do
    describe 'set' do
      before do
        subject.content_type 'text/plain'
      end

      it 'returns value' do
        expect(subject.content_type).to eq 'text/plain'
      end
    end

    it 'returns default' do
      expect(subject.content_type).to be nil
    end
  end

  describe '#cookies' do
    it 'returns an instance of Cookies' do
      expect(subject.cookies).to be_a Grape::Cookies
    end
  end

  describe '#body' do
    describe 'set' do
      before do
        subject.body 'body'
      end

      it 'returns value' do
        expect(subject.body).to eq 'body'
      end
    end

    describe 'false' do
      before do
        subject.body false
      end

      it 'sets status to 204' do
        expect(subject.body).to eq ''
        expect(subject.status).to eq 204
      end
    end

    it 'returns default' do
      expect(subject.body).to be nil
    end
  end

  describe '#file' do
    describe 'set' do
      context 'as file path' do
        let(:file_path) { '/some/file/path' }

        let(:file_response) do
          file_body = Grape::ServeFile::FileBody.new(file_path)
          Grape::ServeFile::FileResponse.new(file_body)
        end

        before do
          subject.file file_path
        end

        it 'returns value wrapped in FileResponse' do
          expect(subject.file).to eq file_response
        end
      end

      context 'as object (backward compatibility)' do
        let(:file_object) { Class.new }

        let(:file_response) do
          Grape::ServeFile::FileResponse.new(file_object)
        end

        before do
          subject.file file_object
        end

        it 'returns value wrapped in FileResponse' do
          expect(subject.file).to eq file_response
        end
      end
    end

    it 'returns default' do
      expect(subject.file).to be nil
    end
  end

  describe '#stream' do
    describe 'set' do
      let(:file_object) { Class.new }

      before do
        subject.header 'Cache-Control', 'cache'
        subject.header 'Content-Length', 123
        subject.header 'Transfer-Encoding', 'base64'
        subject.stream file_object
      end

      it 'returns value wrapped in FileResponse' do
        expect(subject.stream).to eq Grape::ServeFile::FileResponse.new(file_object)
      end

      it 'also sets result of file to value wrapped in FileResponse' do
        expect(subject.file).to eq Grape::ServeFile::FileResponse.new(file_object)
      end

      it 'sets Cache-Control header to no-cache' do
        expect(subject.header['Cache-Control']).to eq 'no-cache'
      end

      it 'sets Content-Length header to nil' do
        expect(subject.header['Content-Length']).to eq nil
      end

      it 'sets Transfer-Encoding header to nil' do
        expect(subject.header['Transfer-Encoding']).to eq nil
      end
    end

    it 'returns default' do
      expect(subject.file).to be nil
    end
  end

  describe '#route' do
    before do
      subject.env['grape.routing_args'] = {}
      subject.env['grape.routing_args'][:route_info] = 'dummy'
    end

    it 'returns route_info' do
      expect(subject.route).to eq 'dummy'
    end
  end

  describe '#present' do
    # see entity_spec.rb for entity representation spec coverage

    describe 'dummy' do
      before do
        subject.present 'dummy'
      end

      it 'presents dummy object' do
        expect(subject.body).to eq 'dummy'
      end
    end

    describe 'with' do
      describe 'entity' do
        let(:entity_mock) do
          entity_mock = Object.new
          allow(entity_mock).to receive(:represent).and_return('dummy')
          entity_mock
        end

        describe 'instance' do
          before do
            subject.present 'dummy', with: entity_mock
          end

          it 'presents dummy object' do
            expect(subject.body).to eq 'dummy'
          end
        end
      end
    end

    describe 'multiple entities' do
      let(:entity_mock_one) do
        entity_mock_one = Object.new
        allow(entity_mock_one).to receive(:represent).and_return(dummy1: 'dummy1')
        entity_mock_one
      end

      let(:entity_mock_two) do
        entity_mock_two = Object.new
        allow(entity_mock_two).to receive(:represent).and_return(dummy2: 'dummy2')
        entity_mock_two
      end

      describe 'instance' do
        before do
          subject.present 'dummy1', with: entity_mock_one
          subject.present 'dummy2', with: entity_mock_two
        end

        it 'presents both dummy objects' do
          expect(subject.body[:dummy1]).to eq 'dummy1'
          expect(subject.body[:dummy2]).to eq 'dummy2'
        end
      end
    end

    describe 'non mergeable entity' do
      let(:entity_mock_one) do
        entity_mock_one = Object.new
        allow(entity_mock_one).to receive(:represent).and_return(dummy1: 'dummy1')
        entity_mock_one
      end

      let(:entity_mock_two) do
        entity_mock_two = Object.new
        allow(entity_mock_two).to receive(:represent).and_return('not a hash')
        entity_mock_two
      end

      describe 'instance' do
        it 'fails' do
          subject.present 'dummy1', with: entity_mock_one
          expect do
            subject.present 'dummy2', with: entity_mock_two
          end.to raise_error ArgumentError, 'Representation of type String cannot be merged.'
        end
      end
    end
  end

  describe '#declared' do
    # see endpoint_spec.rb#declared for spec coverage

    it 'is not available by default' do
      expect { subject.declared({}) }.to raise_error(
        Grape::DSL::InsideRoute::MethodNotYetAvailable
      )
    end
  end
end
