require 'spec_helper'

describe SWD::Debugger::RequestFilter do
  let(:resource_endpoint) { 'https://example.com/resources' }
  let(:request) { HTTP::Message.new_request(:get, URI.parse(resource_endpoint)) }
  let(:response) { HTTP::Message.new_response({:hello => 'world'}.to_json) }
  let(:request_filter) { SWD::Debugger::RequestFilter.new }

  describe '#filter_request' do
    it 'should log request' do
      expect(SWD.logger).to receive(:info).with(
        "======= [SWD] HTTP REQUEST STARTED =======\n" +
        request.dump
      )
      request_filter.filter_request(request)
    end
  end

  describe '#filter_response' do
    it 'should log response' do
      expect(SWD.logger).to receive(:info).with(
        "--------------------------------------------------\n" +
        response.dump +
        "\n======= [SWD] HTTP REQUEST FINISHED ======="
      )
      request_filter.filter_response(request, response)
    end
  end
end