# frozen_string_literal: true
require "rubygems"
require "rspec"
require "rack"
require "coveralls"
Coveralls.wear!

require File.join(File.dirname(__FILE__), "..", "lib", "secure_headers")



USER_AGENTS = {
  edge: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246",
  firefox: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:14.0) Gecko/20100101 Firefox/14.0.1",
  firefox46: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:46.0) Gecko/20100101 Firefox/46.0",
  chrome: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.56 Safari/536.5",
  ie: "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/5.0)",
  opera: "Opera/9.80 (Windows NT 6.1; U; es-ES) Presto/2.9.181 Version/12.00",
  ios5: "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3",
  ios6: "Mozilla/5.0 (iPhone; CPU iPhone OS 614 like Mac OS X) AppleWebKit/536.26 (KHTML like Gecko) Version/6.0 Mobile/10B350 Safari/8536.25",
  safari5: "Mozilla/5.0 (iPad; CPU OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko ) Version/5.1 Mobile/9B176 Safari/7534.48.3",
  safari5_1: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.3 Safari/534.53.10",
  safari6: "Mozilla/5.0 (Macintosh; Intel Mac OS X 1084) AppleWebKit/536.30.1 (KHTML like Gecko) Version/6.0.5 Safari/536.30.1",
  safari10: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/602.2.11 (KHTML, like Gecko) Version/10.0.1 Safari/602.2.11"
}

def expect_default_values(hash)
  expect(hash[SecureHeaders::ContentSecurityPolicyConfig::HEADER_NAME]).to eq("default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'")
  expect(hash[SecureHeaders::ContentSecurityPolicyReportOnlyConfig::HEADER_NAME]).to be_nil
  expect(hash[SecureHeaders::XFrameOptions::HEADER_NAME]).to eq(SecureHeaders::XFrameOptions::DEFAULT_VALUE)
  expect(hash[SecureHeaders::XDownloadOptions::HEADER_NAME]).to eq(SecureHeaders::XDownloadOptions::DEFAULT_VALUE)
  expect(hash[SecureHeaders::StrictTransportSecurity::HEADER_NAME]).to eq(SecureHeaders::StrictTransportSecurity::DEFAULT_VALUE)
  expect(hash[SecureHeaders::XXssProtection::HEADER_NAME]).to eq(SecureHeaders::XXssProtection::DEFAULT_VALUE)
  expect(hash[SecureHeaders::XContentTypeOptions::HEADER_NAME]).to eq(SecureHeaders::XContentTypeOptions::DEFAULT_VALUE)
  expect(hash[SecureHeaders::XPermittedCrossDomainPolicies::HEADER_NAME]).to eq(SecureHeaders::XPermittedCrossDomainPolicies::DEFAULT_VALUE)
  expect(hash[SecureHeaders::ReferrerPolicy::HEADER_NAME]).to be_nil
  expect(hash[SecureHeaders::ExpectCertificateTransparency::HEADER_NAME]).to be_nil
  expect(hash[SecureHeaders::ClearSiteData::HEADER_NAME]).to be_nil
  expect(hash[SecureHeaders::ExpectCertificateTransparency::HEADER_NAME]).to be_nil
end

module SecureHeaders
  class Configuration
    class << self
      def clear_default_config
        remove_instance_variable(:@default_config) if defined?(@default_config)
      end

      def clear_overrides
        remove_instance_variable(:@overrides) if defined?(@overrides)
      end

      def clear_appends
        remove_instance_variable(:@appends) if defined?(@appends)
      end
    end
  end
end

def reset_config
  SecureHeaders::Configuration.clear_default_config
  SecureHeaders::Configuration.clear_overrides
  SecureHeaders::Configuration.clear_appends
end
