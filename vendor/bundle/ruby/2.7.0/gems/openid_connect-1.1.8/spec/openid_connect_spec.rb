require 'spec_helper'

describe OpenIDConnect do
  after { OpenIDConnect.debugging = false }

  its(:logger) { should be_a Logger }
  its(:debugging?) { should == false }

  describe '.debug!' do
    before { OpenIDConnect.debug! }
    its(:debugging?) { should == true }
  end

  describe '.debug' do
    it 'should enable debugging within given block' do
      OpenIDConnect.debug do
        SWD.debugging?.should == true
        WebFinger.debugging?.should == true
        Rack::OAuth2.debugging?.should == true
        OpenIDConnect.debugging?.should == true
      end
      SWD.debugging?.should == false
      Rack::OAuth2.debugging?.should == false
      OpenIDConnect.debugging?.should == false
    end

    it 'should not force disable debugging' do
      SWD.debug!
      WebFinger.debug!
      Rack::OAuth2.debug!
      OpenIDConnect.debug!
      OpenIDConnect.debug do
        SWD.debugging?.should == true
        WebFinger.debugging?.should == true
        Rack::OAuth2.debugging?.should == true
        OpenIDConnect.debugging?.should == true
      end
      SWD.debugging?.should == true
      WebFinger.debugging?.should == true
      Rack::OAuth2.debugging?.should == true
      OpenIDConnect.debugging?.should == true
    end
  end

  describe '.http_client' do
    context 'with http_config' do
      before do
        OpenIDConnect.http_config do |config|
          config.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
      it 'should configure OpenIDConnect, SWD and Rack::OAuth2\'s http_client' do
        [OpenIDConnect, SWD, WebFinger, Rack::OAuth2].each do |klass|
          klass.http_client.ssl_config.verify_mode.should == OpenSSL::SSL::VERIFY_NONE
        end
      end
    end
  end
end