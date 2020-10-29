# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe SecureHeaders do
    before(:each) do
      reset_config
    end

    let(:request) { Rack::Request.new("HTTP_X_FORWARDED_SSL" => "on") }

    it "raises a NotYetConfiguredError if default has not been set" do
      expect do
        SecureHeaders.header_hash_for(request)
      end.to raise_error(Configuration::NotYetConfiguredError)
    end

    it "raises a NotYetConfiguredError if trying to opt-out of unconfigured headers" do
      expect do
        SecureHeaders.opt_out_of_header(request, :csp)
      end.to raise_error(Configuration::NotYetConfiguredError)
    end

    it "raises a AlreadyConfiguredError if trying to configure and default has already been set " do
      Configuration.default
      expect do
        Configuration.default
      end.to raise_error(Configuration::AlreadyConfiguredError)
    end

    it "raises and ArgumentError when referencing an override that has not been set" do
      expect do
        Configuration.default
        SecureHeaders.use_secure_headers_override(request, :missing)
      end.to raise_error(ArgumentError)
    end

    describe "#header_hash_for" do
      it "allows you to opt out of individual headers via API" do
        Configuration.default do |config|
          config.csp = { default_src: %w('self'), script_src: %w('self')}
          config.csp_report_only = config.csp
        end
        SecureHeaders.opt_out_of_header(request, :csp)
        SecureHeaders.opt_out_of_header(request, :csp_report_only)
        SecureHeaders.opt_out_of_header(request, :x_content_type_options)
        hash = SecureHeaders.header_hash_for(request)
        expect(hash["Content-Security-Policy-Report-Only"]).to be_nil
        expect(hash["Content-Security-Policy"]).to be_nil
        expect(hash["X-Content-Type-Options"]).to be_nil
      end

      it "Carries options over when using overrides" do
        Configuration.default do |config|
          config.x_download_options = OPT_OUT
          config.x_permitted_cross_domain_policies = OPT_OUT
        end

        Configuration.override(:api) do |config|
          config.x_frame_options = OPT_OUT
        end

        SecureHeaders.use_secure_headers_override(request, :api)
        hash = SecureHeaders.header_hash_for(request)
        expect(hash["X-Download-Options"]).to be_nil
        expect(hash["X-Permitted-Cross-Domain-Policies"]).to be_nil
        expect(hash["X-Frame-Options"]).to be_nil
      end

      it "Overrides the current default config if default config changes during request" do
        Configuration.default do |config|
          config.x_frame_options = OPT_OUT
        end

        # Dynamically update the default config for this request
        SecureHeaders.override_x_frame_options(request, "DENY")

        Configuration.override(:dynamic_override) do |config|
          config.x_content_type_options = "nosniff"
        end

        SecureHeaders.use_secure_headers_override(request, :dynamic_override)
        hash = SecureHeaders.header_hash_for(request)
        expect(hash["X-Content-Type-Options"]).to eq("nosniff")
        expect(hash["X-Frame-Options"]).to eq("DENY")
      end

      it "allows you to opt out entirely" do
        # configure the disabled-by-default headers to ensure they also do not get set
        Configuration.default do |config|
          config.csp = { default_src: ["example.com"], script_src: %w('self') }
          config.csp_report_only = config.csp
        end
        SecureHeaders.opt_out_of_all_protection(request)
        hash = SecureHeaders.header_hash_for(request)
        expect(hash.count).to eq(0)
      end

      it "allows you to override X-Frame-Options settings" do
        Configuration.default
        SecureHeaders.override_x_frame_options(request, XFrameOptions::DENY)
        hash = SecureHeaders.header_hash_for(request)
        expect(hash[XFrameOptions::HEADER_NAME]).to eq(XFrameOptions::DENY)
      end

      it "allows you to override opting out" do
        Configuration.default do |config|
          config.x_frame_options = OPT_OUT
          config.csp = OPT_OUT
        end

        SecureHeaders.override_x_frame_options(request, XFrameOptions::SAMEORIGIN)
        SecureHeaders.override_content_security_policy_directives(request, default_src: %w(https:), script_src: %w('self'))

        hash = SecureHeaders.header_hash_for(request)
        expect(hash[ContentSecurityPolicyConfig::HEADER_NAME]).to eq("default-src https:; script-src 'self'")
        expect(hash[XFrameOptions::HEADER_NAME]).to eq(XFrameOptions::SAMEORIGIN)
      end

      it "produces a hash of headers with default config" do
        Configuration.default
        hash = SecureHeaders.header_hash_for(request)
        expect_default_values(hash)
      end

      it "does not set the HSTS header if request is over HTTP" do
        plaintext_request = Rack::Request.new({})
        Configuration.default do |config|
          config.hsts = "max-age=123456"
        end
        expect(SecureHeaders.header_hash_for(plaintext_request)[StrictTransportSecurity::HEADER_NAME]).to be_nil
      end

      context "content security policy" do
        let(:chrome_request) {
          Rack::Request.new(request.env.merge("HTTP_USER_AGENT" => USER_AGENTS[:chrome]))
        }

        it "appends a value to csp directive" do
          Configuration.default do |config|
            config.csp = {
              default_src: %w('self'),
              script_src: %w(mycdn.com 'unsafe-inline')
            }
          end

          SecureHeaders.append_content_security_policy_directives(request, script_src: %w(anothercdn.com))
          hash = SecureHeaders.header_hash_for(request)
          expect(hash[ContentSecurityPolicyConfig::HEADER_NAME]).to eq("default-src 'self'; script-src mycdn.com 'unsafe-inline' anothercdn.com")
        end

        it "supports named appends" do
          Configuration.default do |config|
            config.csp = {
              default_src: %w('self'),
              script_src: %w('self')
            }
          end

          Configuration.named_append(:moar_default_sources) do |request|
            { default_src: %w(https:), style_src: %w('self')}
          end

          Configuration.named_append(:how_about_a_script_src_too) do |request|
            { script_src: %w('unsafe-inline')}
          end

          SecureHeaders.use_content_security_policy_named_append(request, :moar_default_sources)
          SecureHeaders.use_content_security_policy_named_append(request, :how_about_a_script_src_too)
          hash = SecureHeaders.header_hash_for(request)

          expect(hash[ContentSecurityPolicyConfig::HEADER_NAME]).to eq("default-src 'self' https:; script-src 'self' 'unsafe-inline'; style-src 'self'")
        end

        it "appends a nonce to a missing script-src value" do
          Configuration.default do |config|
            config.csp = {
              default_src: %w('self'),
              script_src: %w('self')
            }
          end

          SecureHeaders.content_security_policy_script_nonce(request) # should add the value to the header
          hash = SecureHeaders.header_hash_for(chrome_request)
          expect(hash[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/\Adefault-src 'self'; script-src 'self' 'nonce-.*'\z/)
        end

        it "appends a hash to a missing script-src value" do
          Configuration.default do |config|
            config.csp = {
              default_src: %w('self'),
              script_src: %w('self')
            }
          end

          SecureHeaders.append_content_security_policy_directives(request, script_src: %w('sha256-abc123'))
          hash = SecureHeaders.header_hash_for(chrome_request)
          expect(hash[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/\Adefault-src 'self'; script-src 'self' 'sha256-abc123'\z/)
        end

        it "overrides individual directives" do
          Configuration.default do |config|
            config.csp = {
              default_src: %w('self'),
              script_src: %w('self')
            }
          end
          SecureHeaders.override_content_security_policy_directives(request, default_src: %w('none'))
          hash = SecureHeaders.header_hash_for(request)
          expect(hash[ContentSecurityPolicyConfig::HEADER_NAME]).to eq("default-src 'none'; script-src 'self'")
        end

        it "overrides non-existant directives" do
          Configuration.default do |config|
            config.csp = {
              default_src: %w(https:),
              script_src: %w('self')
            }
          end
          SecureHeaders.override_content_security_policy_directives(request, img_src: [ContentSecurityPolicy::DATA_PROTOCOL])
          hash = SecureHeaders.header_hash_for(request)
          expect(hash[ContentSecurityPolicyReportOnlyConfig::HEADER_NAME]).to be_nil
          expect(hash[ContentSecurityPolicyConfig::HEADER_NAME]).to eq("default-src https:; img-src data:; script-src 'self'")
        end

        it "appends a nonce to the script-src when used" do
          Configuration.default do |config|
            config.csp = {
              default_src: %w('self'),
              script_src: %w(mycdn.com),
              style_src: %w('self')
            }
          end

          nonce = SecureHeaders.content_security_policy_script_nonce(chrome_request)

          # simulate the nonce being used multiple times in a request:
          SecureHeaders.content_security_policy_script_nonce(chrome_request)
          SecureHeaders.content_security_policy_script_nonce(chrome_request)
          SecureHeaders.content_security_policy_script_nonce(chrome_request)

          hash = SecureHeaders.header_hash_for(chrome_request)
          expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src mycdn.com 'nonce-#{nonce}' 'unsafe-inline'; style-src 'self'")
        end

        it "does not support the deprecated `report_only: true` format" do
          expect {
            Configuration.default do |config|
              config.csp = {
                default_src: %w('self'),
                report_only: true
              }
            end
          }.to raise_error(ContentSecurityPolicyConfigError)
        end

        it "Raises an error if csp_report_only is used with `report_only: false`" do
          expect do
            Configuration.default do |config|
              config.csp_report_only = {
                default_src: %w('self'),
                script_src: %w('self'),
                report_only: false
              }
            end
          end.to raise_error(ContentSecurityPolicyConfigError)
        end

        context "setting two headers" do
          before(:each) do
            Configuration.default do |config|
              config.csp = {
                default_src: %w('self'),
                script_src: %w('self')
              }
              config.csp_report_only = config.csp
            end
          end

          it "sets identical values when the configs are the same" do
            reset_config
            Configuration.default do |config|
              config.csp = {
                default_src: %w('self'),
                script_src: %w('self')
              }
              config.csp_report_only = {
                default_src: %w('self'),
                script_src: %w('self')
              }
            end

            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src 'self'")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src 'self'")
          end

          it "sets different headers when the configs are different" do
            reset_config
            Configuration.default do |config|
              config.csp = {
                default_src: %w('self'),
                script_src: %w('self')
              }
              config.csp_report_only = config.csp.merge({script_src: %w(foo.com)})
            end

            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src 'self'")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src foo.com")
          end

          it "allows you to opt-out of enforced CSP" do
            reset_config
            Configuration.default do |config|
              config.csp = SecureHeaders::OPT_OUT
              config.csp_report_only = {
                default_src: %w('self'),
                script_src: %w('self')
              }
            end

            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to be_nil
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src 'self'")
          end

          it "allows appending to the enforced policy" do
            SecureHeaders.append_content_security_policy_directives(request, {script_src: %w(anothercdn.com)}, :enforced)
            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src 'self' anothercdn.com")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src 'self'")
          end

          it "allows appending to the report only policy" do
            SecureHeaders.append_content_security_policy_directives(request, {script_src: %w(anothercdn.com)}, :report_only)
            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src 'self'")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src 'self' anothercdn.com")
          end

          it "allows appending to both policies" do
            SecureHeaders.append_content_security_policy_directives(request, {script_src: %w(anothercdn.com)}, :both)
            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src 'self' anothercdn.com")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src 'self' anothercdn.com")
          end

          it "allows overriding the enforced policy" do
            SecureHeaders.override_content_security_policy_directives(request, {script_src: %w(anothercdn.com)}, :enforced)
            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src anothercdn.com")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src 'self'")
          end

          it "allows overriding the report only policy" do
            SecureHeaders.override_content_security_policy_directives(request, {script_src: %w(anothercdn.com)}, :report_only)
            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src 'self'")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src anothercdn.com")
          end

          it "allows overriding both policies" do
            SecureHeaders.override_content_security_policy_directives(request, {script_src: %w(anothercdn.com)}, :both)
            hash = SecureHeaders.header_hash_for(request)
            expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src anothercdn.com")
            expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src anothercdn.com")
          end

          context "when inferring which config to modify" do
            it "updates the enforced header when configured" do
              reset_config
              Configuration.default do |config|
                config.csp = {
                  default_src: %w('self'),
                  script_src: %w('self')
                }
              end
              SecureHeaders.append_content_security_policy_directives(request, {script_src: %w(anothercdn.com)})

              hash = SecureHeaders.header_hash_for(request)
              expect(hash["Content-Security-Policy"]).to eq("default-src 'self'; script-src 'self' anothercdn.com")
              expect(hash["Content-Security-Policy-Report-Only"]).to be_nil
            end

            it "updates the report only header when configured" do
              reset_config
              Configuration.default do |config|
                config.csp = OPT_OUT
                config.csp_report_only = {
                  default_src: %w('self'),
                  script_src: %w('self')
                }
              end
              SecureHeaders.append_content_security_policy_directives(request, {script_src: %w(anothercdn.com)})

              hash = SecureHeaders.header_hash_for(request)
              expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src 'self'; script-src 'self' anothercdn.com")
              expect(hash["Content-Security-Policy"]).to be_nil
            end

            it "updates both headers if both are configured" do
              reset_config
              Configuration.default do |config|
                config.csp = {
                  default_src: %w(enforced.com),
                  script_src: %w('self')
                }
                config.csp_report_only = {
                  default_src: %w(reportonly.com),
                  script_src: %w('self')
                }
              end
              SecureHeaders.append_content_security_policy_directives(request, {script_src: %w(anothercdn.com)})

              hash = SecureHeaders.header_hash_for(request)
              expect(hash["Content-Security-Policy"]).to eq("default-src enforced.com; script-src 'self' anothercdn.com")
              expect(hash["Content-Security-Policy-Report-Only"]).to eq("default-src reportonly.com; script-src 'self' anothercdn.com")
            end

          end
        end
      end
    end

    context "validation" do
      it "validates your hsts config upon configuration" do
        expect do
          Configuration.default do |config|
            config.hsts = "lol"
          end
        end.to raise_error(STSConfigError)
      end

      it "validates your csp config upon configuration" do
        expect do
          Configuration.default do |config|
            config.csp = { ContentSecurityPolicy::DEFAULT_SRC => "123456" }
          end
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "raises errors for unknown directives" do
        expect do
          Configuration.default do |config|
            config.csp = { made_up_directive: "123456" }
          end
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "validates your xfo config upon configuration" do
        expect do
          Configuration.default do |config|
            config.x_frame_options = "NOPE"
          end
        end.to raise_error(XFOConfigError)
      end

      it "validates your xcto config upon configuration" do
        expect do
          Configuration.default do |config|
            config.x_content_type_options = "lol"
          end
        end.to raise_error(XContentTypeOptionsConfigError)
      end

      it "validates your clear site data config upon configuration" do
        expect do
          Configuration.default do |config|
            config.clear_site_data = 1
          end
        end.to raise_error(ClearSiteDataConfigError)
      end

      it "validates your x_xss config upon configuration" do
        expect do
          Configuration.default do |config|
            config.x_xss_protection = "lol"
          end
        end.to raise_error(XXssProtectionConfigError)
      end

      it "validates your xdo config upon configuration" do
        expect do
          Configuration.default do |config|
            config.x_download_options = "lol"
          end
        end.to raise_error(XDOConfigError)
      end

      it "validates your x_permitted_cross_domain_policies config upon configuration" do
        expect do
          Configuration.default do |config|
            config.x_permitted_cross_domain_policies = "lol"
          end
        end.to raise_error(XPCDPConfigError)
      end

      it "validates your referrer_policy config upon configuration" do
        expect do
          Configuration.default do |config|
            config.referrer_policy = "lol"
          end
        end.to raise_error(ReferrerPolicyConfigError)
      end

      it "validates your cookies config upon configuration" do
        expect do
          Configuration.default do |config|
            config.cookies = { secure: "lol" }
          end
        end.to raise_error(CookiesConfigError)
      end
    end
  end
end
