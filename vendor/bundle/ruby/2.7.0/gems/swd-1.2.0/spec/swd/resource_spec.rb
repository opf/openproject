require 'spec_helper'

describe SWD::Resource do
  subject { resource }
  let(:resource) { SWD::Resource.new attributes }
  let(:attributes) do
    {
      :principal => 'mailto:joe@example.com',
      :service => 'urn:adatum.com:calendar',
      :host => 'example.com'
    }
  end

  its(:path) { should == '/.well-known/simple-web-discovery' }

  [:principal, :service, :host].each do |key|
    it "should require #{key}" do
      expect do
        SWD::Resource.new attributes.merge(key => nil)
      end.to raise_error AttrRequired::AttrMissing
    end
  end

  describe '#discover!' do
    context 'when succeeded' do
      it 'should return SWD::Response' do
        mock_json resource.endpoint, 'success' do
          res = resource.discover!
          res.should be_a SWD::Response
          res.locations == ['http://calendars.proseware.com/calendars/joseph']
          res.location == 'http://calendars.proseware.com/calendars/joseph'
          res.raw == {
            'locations' => ['http://calendars.proseware.com/calendars/joseph']
          }
        end
      end
    end

    context 'when redirected' do
      it 'should follow redirect' do
        expect(resource).to receive(:redirect_to).with(
          'https://swd.proseware.com/swd_server', nil
        )
        mock_json resource.endpoint, 'redirect' do
          resource.discover!
        end
      end

      context 'when expired' do
        it 'should return SWD::Response' do
          mock_json resource.endpoint, 'redirect_expired' do
            expect { res = resource.discover! }.to raise_error SWD::Resource::Expired
          end
        end
      end

      context 'otherwise' do
        it 'should return SWD::Response' do
          mock_json resource.endpoint, 'redirect' do
            mock_json 'https://swd.proseware.com/swd_server', 'success', :query => {
              :principal => 'mailto:joe@example.com',
              :service => 'urn:adatum.com:calendar'
            } do
              res = resource.discover!
              res.should be_a SWD::Response
            end
          end
        end
      end
    end

    describe 'error handling' do
      before(:all) do
        module SWD
          class << self
            module HttpClientWithCached
              def http_client
                @http_client ||= super
              end
            end
            prepend HttpClientWithCached
          end
        end
      end

      after(:all) do
        module SWD
          class << self
            module HttpClientWithCacheCleared
              def http_client
                @http_client = nil
                super
              end
            end
            prepend HttpClientWithCacheCleared
          end
        end
      end

      context 'when invalid SSL cert' do
        it do
          expect(SWD.http_client).to receive(:get_content).and_raise(OpenSSL::SSL::SSLError)
          expect { res = resource.discover! }.to raise_error SWD::Exception
        end
      end

      context 'when invalid JSON' do
        it do
          expect(SWD.http_client).to receive(:get_content).and_raise(JSON::ParserError)
          expect { res = resource.discover! }.to raise_error SWD::Exception
        end
      end

      context 'when SocketError' do
        it do
          expect(SWD.http_client).to receive(:get_content).and_raise(SocketError)
          expect { res = resource.discover! }.to raise_error SWD::Exception
        end
      end

      context 'when BadResponseError without response' do
        it do
          expect(SWD.http_client).to receive(:get_content).and_raise(HTTPClient::BadResponseError.new(''))
          expect { res = resource.discover! }.to raise_error SWD::Exception
        end
      end

      context 'when bad request' do
        it 'should raise SWD::BadRequest' do
          mock_json resource.endpoint, 'blank', :status => 400 do
            expect { res = resource.discover! }.to raise_error SWD::BadRequest
          end
        end
      end

      context 'when unauthorized' do
        it 'should raise SWD::Unauthorized' do
          mock_json resource.endpoint, 'blank', :status => 401 do
            expect { res = resource.discover! }.to raise_error SWD::Unauthorized
          end
        end
      end

      context 'when forbidden' do
        it 'should raise SWD::Forbidden' do
          mock_json resource.endpoint, 'blank', :status => 403 do
            expect { res = resource.discover! }.to raise_error SWD::Forbidden
          end
        end
      end

      context 'when not found' do
        it 'should raise SWD::NotFound' do
          mock_json resource.endpoint, 'blank', :status => 404 do
            expect { res = resource.discover! }.to raise_error SWD::NotFound
          end
        end
      end

      context 'when other error happened' do
        it 'should raise SWD::HttpError' do
          mock_json resource.endpoint, 'blank', :status => 500 do
            expect { res = resource.discover! }.to raise_error SWD::HttpError
          end
        end
      end
    end
  end

  describe '#endpoint' do
    its(:endpoint) { should be_instance_of URI::HTTPS }
    context 'with URI::HTTP builder' do
      before do
        @original_url_builder = SWD.url_builder
        SWD.url_builder = URI::HTTP
      end
      after do
        SWD.url_builder = @original_url_builder
      end
      its(:endpoint) { should be_instance_of URI::HTTP }
    end
  end
end