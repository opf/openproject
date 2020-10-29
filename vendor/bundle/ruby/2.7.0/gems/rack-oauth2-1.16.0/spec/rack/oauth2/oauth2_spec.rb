require 'spec_helper'

describe Rack::OAuth2 do
  subject { Rack::OAuth2 }
  after { Rack::OAuth2.debugging = false }

  its(:logger) { should be_a Logger }
  its(:debugging?) { should == false }

  describe '.debug!' do
    before { Rack::OAuth2.debug! }
    its(:debugging?) { should == true }
  end

  describe '.debug' do
    it 'should enable debugging within given block' do
      Rack::OAuth2.debug do
        Rack::OAuth2.debugging?.should == true
      end
      Rack::OAuth2.debugging?.should == false
    end

    it 'should not force disable debugging' do
      Rack::OAuth2.debug!
      Rack::OAuth2.debug do
        Rack::OAuth2.debugging?.should == true
      end
      Rack::OAuth2.debugging?.should == true
    end
  end

  describe '.http_config' do
    context 'when request_filter added' do
      context 'when "debug!" is called' do
        after { Rack::OAuth2.reset_http_config! }

        it 'should put Debugger::RequestFilter at last' do
          Rack::OAuth2.debug!
          Rack::OAuth2.http_config do |config|
            config.request_filter << Proc.new {}
          end
          Rack::OAuth2.http_client.request_filter.last.should be_instance_of Rack::OAuth2::Debugger::RequestFilter
        end

        it 'should reset_http_config' do
          Rack::OAuth2.debug!
          Rack::OAuth2.http_config do |config|
            config.request_filter << Proc.new {}
          end
          size = Rack::OAuth2.http_client.request_filter.size
          Rack::OAuth2.reset_http_config!
          Rack::OAuth2.http_client.request_filter.size.should == size - 1
        end

      end
    end
  end

  describe ".http_client" do
    context "when local_http_config is used" do
      it "should correctly set request_filter" do
        clnt1 = Rack::OAuth2.http_client
        clnt2 = Rack::OAuth2.http_client("my client") do |config|
          config.request_filter << Proc.new {}
        end
        clnt3 = Rack::OAuth2.http_client

        clnt1.request_filter.size.should == clnt3.request_filter.size
        clnt1.request_filter.size.should == clnt2.request_filter.size - 1

      end
    end
  end
end