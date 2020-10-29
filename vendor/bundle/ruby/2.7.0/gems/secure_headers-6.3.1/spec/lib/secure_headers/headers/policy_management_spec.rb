# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe PolicyManagement do
    before(:each) do
      reset_config
      Configuration.default
    end

    let (:default_opts) do
      {
        default_src: %w(https:),
        img_src: %w(https: data:),
        script_src: %w('unsafe-inline' 'unsafe-eval' https: data:),
        style_src: %w('unsafe-inline' https: about:),
        report_uri: %w(/csp_report)
      }
    end

    describe "#validate_config!" do
      it "accepts all keys" do
        # (pulled from README)
        config = {
          # "meta" values. these will shape the header, but the values are not included in the header.
          report_only:  false,
          preserve_schemes: true, # default: false. Schemes are removed from host sources to save bytes and discourage mixed content.

          # directive values: these values will directly translate into source directives
          default_src: %w(https: 'self'),

          base_uri: %w('self'),
          block_all_mixed_content: true, # see [http://www.w3.org/TR/mixed-content/](http://www.w3.org/TR/mixed-content/)
          connect_src: %w(wss:),
          child_src: %w('self' *.twimg.com itunes.apple.com),
          font_src: %w('self' data:),
          form_action: %w('self' github.com),
          frame_ancestors: %w('none'),
          frame_src: %w('self' *.twimg.com itunes.apple.com),
          img_src: %w(mycdn.com data:),
          manifest_src: %w(manifest.com),
          media_src: %w(utoob.com),
          navigate_to: %w(netscape.com),
          object_src: %w('self'),
          plugin_types: %w(application/x-shockwave-flash),
          prefetch_src: %w(fetch.com),
          require_sri_for: %w(script style),
          script_src: %w('self'),
          style_src: %w('unsafe-inline'),
          upgrade_insecure_requests: true, # see https://www.w3.org/TR/upgrade-insecure-requests/
          worker_src: %w(worker.com),

          report_uri: %w(https://example.com/uri-directive),
        }

        ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(config))
      end

      it "requires a :default_src value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(script_src: %w('self')))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "requires a :script_src value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_src: %w('self')))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "accepts OPT_OUT as a script-src value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_src: %w('self'), script_src: OPT_OUT))
        end.to_not raise_error
      end

      it "requires :report_only to be a truthy value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(report_only: "steve")))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "requires :preserve_schemes to be a truthy value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(preserve_schemes: "steve")))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "requires :block_all_mixed_content to be a boolean value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(block_all_mixed_content: "steve")))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "requires :upgrade_insecure_requests to be a boolean value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(upgrade_insecure_requests: "steve")))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "requires all source lists to be an array of strings" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_src: "steve"))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "allows nil values" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_src: %w('self'), script_src: ["https:", nil]))
        end.to_not raise_error
      end

      it "rejects unknown directives / config" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_src: %w('self'), default_src_totally_mispelled: "steve"))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      # this is mostly to ensure people don't use the antiquated shorthands common in other configs
      it "performs light validation on source lists" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_src: %w(self none inline eval), script_src: %w('self')))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "rejects anything not of the form allow-* as a sandbox value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(sandbox: ["steve"])))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "accepts anything of the form allow-* as a sandbox value " do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(sandbox: ["allow-foo"])))
        end.to_not raise_error
      end

      it "accepts true as a sandbox policy" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(sandbox: true)))
        end.to_not raise_error
      end

      it "rejects anything not of the form type/subtype as a plugin-type value" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(plugin_types: ["steve"])))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "accepts anything of the form type/subtype as a plugin-type value " do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(plugin_types: ["application/pdf"])))
        end.to_not raise_error
      end

      it "doesn't allow report_only to be set in a non-report-only config" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyConfig.new(default_opts.merge(report_only: true)))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end

      it "allows report_only to be set in a report-only config" do
        expect do
          ContentSecurityPolicy.validate_config!(ContentSecurityPolicyReportOnlyConfig.new(default_opts.merge(report_only: true)))
        end.to_not raise_error
      end
    end

    describe "#combine_policies" do
      before(:each) do
        reset_config
      end
      it "combines the default-src value with the override if the directive was unconfigured" do
        Configuration.default do |config|
          config.csp = {
            default_src: %w(https:),
            script_src: %w('self'),
          }
        end
        default_policy = Configuration.dup
        combined_config = ContentSecurityPolicy.combine_policies(default_policy.csp.to_h, style_src: %w(anothercdn.com))
        csp = ContentSecurityPolicy.new(combined_config)
        expect(csp.name).to eq(ContentSecurityPolicyConfig::HEADER_NAME)
        expect(csp.value).to eq("default-src https:; script-src 'self'; style-src https: anothercdn.com")
      end

      it "combines directives where the original value is nil and the hash is frozen" do
        Configuration.default do |config|
          config.csp = {
            default_src: %w('self'),
            script_src: %w('self'),
            report_only: false
          }.freeze
        end
        report_uri = "https://report-uri.io/asdf"
        default_policy = Configuration.dup
        combined_config = ContentSecurityPolicy.combine_policies(default_policy.csp.to_h, report_uri: [report_uri])
        csp = ContentSecurityPolicy.new(combined_config)
        expect(csp.value).to include("report-uri #{report_uri}")
      end

      it "does not combine the default-src value for directives that don't fall back to default sources" do
        Configuration.default do |config|
          config.csp = {
            default_src: %w('self'),
            script_src: %w('self'),
            report_only: false
          }.freeze
        end
        non_default_source_additions = ContentSecurityPolicy::NON_FETCH_SOURCES.each_with_object({}) do |directive, hash|
          hash[directive] = %w("http://example.org)
        end
        default_policy = Configuration.dup
        combined_config = ContentSecurityPolicy.combine_policies(default_policy.csp.to_h, non_default_source_additions)

        ContentSecurityPolicy::NON_FETCH_SOURCES.each do |directive|
          expect(combined_config[directive]).to eq(%w("http://example.org))
        end
      end

      it "overrides the report_only flag" do
        Configuration.default do |config|
          config.csp = {
            default_src: %w('self'),
            script_src: %w('self'),
            report_only: false
          }
        end
        default_policy = Configuration.dup
        combined_config = ContentSecurityPolicy.combine_policies(default_policy.csp.to_h, report_only: true)
        csp = ContentSecurityPolicy.new(combined_config)
        expect(csp.name).to eq(ContentSecurityPolicyReportOnlyConfig::HEADER_NAME)
      end

      it "overrides the :block_all_mixed_content flag" do
        Configuration.default do |config|
          config.csp = {
            default_src: %w(https:),
            script_src: %w('self'),
            block_all_mixed_content: false
          }
        end
        default_policy = Configuration.dup
        combined_config = ContentSecurityPolicy.combine_policies(default_policy.csp.to_h, block_all_mixed_content: true)
        csp = ContentSecurityPolicy.new(combined_config)
        expect(csp.value).to eq("default-src https:; block-all-mixed-content; script-src 'self'")
      end

      it "raises an error if appending to a OPT_OUT policy" do
        Configuration.default do |config|
          config.csp = OPT_OUT
        end
        default_policy = Configuration.dup
        expect do
          ContentSecurityPolicy.combine_policies(default_policy.csp.to_h, script_src: %w(anothercdn.com))
        end.to raise_error(ContentSecurityPolicyConfigError)
      end
    end
  end
end
