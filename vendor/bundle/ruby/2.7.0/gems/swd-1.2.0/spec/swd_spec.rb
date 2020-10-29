require 'spec_helper'

describe SWD do
  after { SWD.debugging = false }

  its(:logger) { should be_a Logger }
  its(:debugging?) { should == false }
  its(:cache) { should be_a SWD::Cache }

  describe '#discover!' do
    it 'should return SWD::Response' do
      mock_json "https://example.com/.well-known/simple-web-discovery", 'success', :query => {
        :principal => 'mailto:joe@example.com',
        :service => 'urn:adatum.com:calendar'
      } do
        SWD.discover!(
          :principal => 'mailto:joe@example.com',
          :service => 'urn:adatum.com:calendar',
          :host => 'example.com'
        ).should be_a SWD::Response
      end
    end

    context 'when port specified' do
      it 'should use it' do
        mock_json "https://example.com:8080/.well-known/simple-web-discovery", 'success', :query => {
          :principal => 'mailto:joe@example.com',
          :service => 'urn:adatum.com:calendar'
        } do
          SWD.discover!(
            :principal => 'mailto:joe@example.com',
            :service => 'urn:adatum.com:calendar',
            :host => 'example.com',
            :port => 8080
          ).should be_a SWD::Response
        end
      end

      context 'when redirected to different host' do
        context 'with port' do
          it 'should success' do
            mock_json "https://example.com:8080/.well-known/simple-web-discovery", 'redirect_with_port', :query => {
              :principal => 'mailto:joe@example.com',
              :service => 'urn:adatum.com:calendar'
            } do
              mock_json "https://swd.proseware.com:8080/swd_server", 'success', :query => {
                :principal => 'mailto:joe@example.com',
                :service => 'urn:adatum.com:calendar'
              } do
                SWD.discover!(
                  :principal => 'mailto:joe@example.com',
                  :service => 'urn:adatum.com:calendar',
                  :host => 'example.com',
                  :port => 8080
                ).should be_a SWD::Response
              end
            end
          end
        end

        context 'without port' do
          it 'should success' do
            mock_json "https://example.com:8080/.well-known/simple-web-discovery", 'redirect', :query => {
              :principal => 'mailto:joe@example.com',
              :service => 'urn:adatum.com:calendar'
            } do
              mock_json "https://swd.proseware.com/swd_server", 'success', :query => {
                :principal => 'mailto:joe@example.com',
                :service => 'urn:adatum.com:calendar'
              } do
                SWD.discover!(
                  :principal => 'mailto:joe@example.com',
                  :service => 'urn:adatum.com:calendar',
                  :host => 'example.com',
                  :port => 8080
                ).should be_a SWD::Response
              end
            end
          end
        end
      end
    end
  end

  describe '.debug!' do
    before { SWD.debug! }
    its(:debugging?) { should == true }
  end

  describe '.debug' do
    it 'should enable debugging within given block' do
      SWD.debug do
        SWD.debugging?.should == true
      end
      SWD.debugging?.should == false
    end

    it 'should not force disable debugging' do
      SWD.debug!
      SWD.debug do
        SWD.debugging?.should == true
      end
      SWD.debugging?.should == true
    end
  end

  describe '.http_client' do
    context 'with http_config' do
      before do
        SWD.http_config do |config|
          config.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
      it 'should configure http_client' do
        SWD.http_client.ssl_config.verify_mode.should == OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end