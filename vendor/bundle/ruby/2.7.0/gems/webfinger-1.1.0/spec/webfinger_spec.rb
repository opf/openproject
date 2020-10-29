require 'spec_helper'

describe WebFinger do
  let(:resource) { 'acct:nov@example.com' }

  describe '#discover!' do
    {
      'example.com'             => 'https://example.com',
      'example.com/~nov/'       => 'https://example.com',
      'nov@example.com'         => 'https://example.com',
      'nov.matake@example.com'  => 'https://example.com',
      'acct:nov@example.com'    => 'https://example.com',
      'mailto:nov@example.com'  => 'https://example.com',
      'device:example.com'      => 'https://example.com',
      'unknown:nov@example.com' => 'https://example.com',
      'http://example.com/nov'  => 'https://example.com',
      'https://example.com/nov' => 'https://example.com',
      'example.com:8080'             => 'https://example.com:8080',
      'example.com:8080/~nov/'       => 'https://example.com:8080',
      'nov@example.com:8080'         => 'https://example.com:8080',
      'nov.matake@example.com:8080'  => 'https://example.com:8080',
      'acct:nov@example.com:8080'    => 'https://example.com:8080',
      'mailto:nov@example.com:8080'  => 'https://example.com:8080',
      'device:example.com:8080'      => 'https://example.com:8080',
      'unknown:nov@example.com:8080' => 'https://example.com:8080',
      'http://example.com:8080'      => 'https://example.com:8080',
      'https://example.com:8080'     => 'https://example.com:8080',
      'discover.example.com'             => 'https://discover.example.com',
      'discover.example.com/~nov/'       => 'https://discover.example.com',
      'nov@discover.example.com'         => 'https://discover.example.com',
      'nov.matake@discover.example.com'  => 'https://discover.example.com',
      'acct:nov@discover.example.com'    => 'https://discover.example.com',
      'mailto:nov@discover.example.com'  => 'https://discover.example.com',
      'device:discover.example.com'      => 'https://discover.example.com',
      'unknown:nov@discover.example.com' => 'https://discover.example.com',
      'http://discover.example.com/nov'  => 'https://discover.example.com',
      'https://discover.example.com/nov' => 'https://discover.example.com',
      'discover.example.com:8080'             => 'https://discover.example.com:8080',
      'discover.example.com:8080/~nov/'       => 'https://discover.example.com:8080',
      'nov@discover.example.com:8080'         => 'https://discover.example.com:8080',
      'nov.matake@discover.example.com:8080'  => 'https://discover.example.com:8080',
      'acct:nov@discover.example.com:8080'    => 'https://discover.example.com:8080',
      'mailto:nov@discover.example.com:8080'  => 'https://discover.example.com:8080',
      'device:discover.example.com:8080'      => 'https://discover.example.com:8080',
      'unknown:nov@discover.example.com:8080' => 'https://discover.example.com:8080',
      'http://discover.example.com:8080/nov'  => 'https://discover.example.com:8080',
      'https://discover.example.com:8080/nov' => 'https://discover.example.com:8080'
    }.each do |resource, base_url|
      endpoint = File.join base_url, '/.well-known/webfinger'
      context "when resource=#{resource}" do
        it "should access to #{endpoint}" do
          mock_json endpoint, 'all', query: {resource: resource} do
            response = WebFinger.discover! resource
            response.should be_instance_of WebFinger::Response
          end
        end
      end
    end

    context 'with rel option' do
      shared_examples_for :discovery_with_rel do
        let(:query_string) do
          query_params = [{resource: resource}.to_query]
          Array(rel).each do |_rel_|
            query_params << {rel: _rel_}.to_query
          end
          query_params.join('&')
        end

        it 'should request with rel' do
          query_string.scan('rel').count.should == Array(rel).count
          mock_json 'https://example.com/.well-known/webfinger', 'all', query: query_string do
            response = WebFinger.discover! resource, rel: rel
            response.should be_instance_of WebFinger::Response
          end
        end
      end

      context 'when single rel' do
        let(:rel) { 'http://openid.net/specs/connect/1.0/issuer' }
        it_behaves_like :discovery_with_rel
      end

      context 'when multiple rel' do
        let(:rel) { ['http://openid.net/specs/connect/1.0/issuer', 'vcard'] }
        it_behaves_like :discovery_with_rel
      end
    end

    context 'when error' do
      {
        400 => WebFinger::BadRequest,
        401 => WebFinger::Unauthorized,
        403 => WebFinger::Forbidden,
        404 => WebFinger::NotFound,
        500 => WebFinger::HttpError
      }.each do |status, exception_class|
        context "when status=#{status}" do
          it "should raise #{exception_class}" do
            expect do
              mock_json 'https://example.com/.well-known/webfinger', 'all', query: {resource: resource}, status: [status, 'HTTPError'] do
                response = WebFinger.discover! resource
              end
            end.to raise_error exception_class
          end
        end
      end
    end
  end

  describe '#logger' do
    subject { WebFinger.logger }

    context 'as default' do
      it { should be_instance_of Logger }
    end

    context 'when specified' do
      let(:logger) { 'Rails.logger or something' }
      before { WebFinger.logger = logger }
      it { should == logger }
    end
  end

  describe '#debugging?' do
    subject { WebFinger.debugging? }

    context 'as default' do
      it { should == false }
    end

    context 'when debugging' do
      before { WebFinger.debug! }
      it { should == true }

      context 'when debugging mode canceled' do
        before { WebFinger.debugging = false }
        it { should == false }
      end
    end
  end

  describe '#url_builder' do
    subject { WebFinger.url_builder }

    context 'as default' do
      it { should == URI::HTTPS }
    end

    context 'when specified' do
      let(:url_builder) { 'URI::HTTP or something' }
      before { WebFinger.url_builder = url_builder }
      it { should == url_builder }
    end
  end

  describe '#http_client' do
    subject { WebFinger.http_client }

    describe '#request_filter' do
      subject { WebFinger.http_client.request_filter.collect(&:class) }

      context 'as default' do
        it { should_not include WebFinger::Debugger::RequestFilter }
      end

      context 'when debugging' do
        before { WebFinger.debug! }
        it { should include WebFinger::Debugger::RequestFilter }
      end
    end
  end
end