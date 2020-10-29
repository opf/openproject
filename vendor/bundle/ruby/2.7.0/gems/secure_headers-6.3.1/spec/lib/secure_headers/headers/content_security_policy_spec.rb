# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe ContentSecurityPolicy do
    let (:default_opts) do
      {
        default_src: %w(https:),
        img_src: %w(https: data:),
        script_src: %w('unsafe-inline' 'unsafe-eval' https: data:),
        style_src: %w('unsafe-inline' https: about:),
        report_uri: %w(/csp_report)
      }
    end

    describe "#name" do
      context "when in report-only mode" do
        specify { expect(ContentSecurityPolicy.new(default_opts.merge(report_only: true)).name).to eq(ContentSecurityPolicyReportOnlyConfig::HEADER_NAME) }
      end

      context "when in enforce mode" do
        specify { expect(ContentSecurityPolicy.new(default_opts).name).to eq(ContentSecurityPolicyConfig::HEADER_NAME) }
      end
    end

    describe "#value" do
      it "uses a safe but non-breaking default value" do
        expect(ContentSecurityPolicy.new.value).to eq("default-src https:; form-action 'self'; img-src https: data: 'self'; object-src 'none'; script-src https:; style-src 'self' 'unsafe-inline' https:")
      end

      it "deprecates and escapes semicolons in directive source lists" do
        expect(Kernel).to receive(:warn).with(%(frame_ancestors contains a ; in "google.com;script-src *;.;" which will raise an error in future versions. It has been replaced with a blank space.))
        expect(ContentSecurityPolicy.new(frame_ancestors: %w(https://google.com;script-src https://*;.;)).value).to eq("frame-ancestors google.com script-src * .")
      end

      it "deprecates and escapes semicolons in directive source lists" do
        expect(Kernel).to receive(:warn).with(%(frame_ancestors contains a \n in "\\nfoo.com\\nhacked" which will raise an error in future versions. It has been replaced with a blank space.))
        expect(ContentSecurityPolicy.new(frame_ancestors: ["\nfoo.com\nhacked"]).value).to eq("frame-ancestors  foo.com hacked")
      end

      it "discards 'none' values if any other source expressions are present" do
        csp = ContentSecurityPolicy.new(default_opts.merge(child_src: %w('self' 'none')))
        expect(csp.value).not_to include("'none'")
      end

      it "discards source expressions (besides unsafe-* and non-host source values) when * is present" do
        csp = ContentSecurityPolicy.new(default_src: %w(* 'unsafe-inline' 'unsafe-eval' http: https: example.org data: blob:))
        expect(csp.value).to eq("default-src * 'unsafe-inline' 'unsafe-eval' data: blob:")
      end

      it "minifies source expressions based on overlapping wildcards" do
        config = {
          default_src: %w(a.example.org b.example.org *.example.org https://*.example.org)
        }
        csp = ContentSecurityPolicy.new(config)
        expect(csp.value).to eq("default-src *.example.org")
      end

      it "removes http/s schemes from hosts" do
        csp = ContentSecurityPolicy.new(default_src: %w(https://example.org))
        expect(csp.value).to eq("default-src example.org")
      end

      it "does not build directives with a value of OPT_OUT (and bypasses directive requirements)" do
        csp = ContentSecurityPolicy.new(default_src: %w(https://example.org), script_src: OPT_OUT)
        expect(csp.value).to eq("default-src example.org")
      end

      it "does not remove schemes from report-uri values" do
        csp = ContentSecurityPolicy.new(default_src: %w(https:), report_uri: %w(https://example.org))
        expect(csp.value).to eq("default-src https:; report-uri https://example.org")
      end

      it "does not remove schemes when :preserve_schemes is true" do
        csp = ContentSecurityPolicy.new(default_src: %w(https://example.org), preserve_schemes: true)
        expect(csp.value).to eq("default-src https://example.org")
      end

      it "removes nil from source lists" do
        csp = ContentSecurityPolicy.new(default_src: ["https://example.org", nil])
        expect(csp.value).to eq("default-src example.org")
      end

      it "does not add a directive if the value is an empty array (or all nil)" do
        csp = ContentSecurityPolicy.new(default_src: ["https://example.org"], script_src: [nil])
        expect(csp.value).to eq("default-src example.org")
      end

      it "does not add a directive if the value is nil" do
        csp = ContentSecurityPolicy.new(default_src: ["https://example.org"], script_src: nil)
        expect(csp.value).to eq("default-src example.org")
      end

      it "does add a boolean directive if the value is true" do
        csp = ContentSecurityPolicy.new(default_src: ["https://example.org"], block_all_mixed_content: true, upgrade_insecure_requests: true)
        expect(csp.value).to eq("default-src example.org; block-all-mixed-content; upgrade-insecure-requests")
      end

      it "does not add a boolean directive if the value is false" do
        csp = ContentSecurityPolicy.new(default_src: ["https://example.org"], block_all_mixed_content: true, upgrade_insecure_requests: false)
        expect(csp.value).to eq("default-src example.org; block-all-mixed-content")
      end

      it "deduplicates any source expressions" do
        csp = ContentSecurityPolicy.new(default_src: %w(example.org example.org example.org))
        expect(csp.value).to eq("default-src example.org")
      end

      it "creates maximally strict sandbox policy when passed no sandbox token values" do
        csp = ContentSecurityPolicy.new(default_src: %w(example.org), sandbox: [])
        expect(csp.value).to eq("default-src example.org; sandbox")
      end

      it "creates maximally strict sandbox policy when passed true" do
        csp = ContentSecurityPolicy.new(default_src: %w(example.org), sandbox: true)
        expect(csp.value).to eq("default-src example.org; sandbox")
      end

      it "creates sandbox policy when passed valid sandbox token values" do
        csp = ContentSecurityPolicy.new(default_src: %w(example.org), sandbox: %w(allow-forms allow-scripts))
        expect(csp.value).to eq("default-src example.org; sandbox allow-forms allow-scripts")
      end

      it "does not emit a warning when using frame-src" do
        expect(Kernel).to_not receive(:warn)
        ContentSecurityPolicy.new(default_src: %w('self'), frame_src: %w('self')).value
      end

      it "allows script as a require-sri-src" do
        csp = ContentSecurityPolicy.new(default_src: %w('self'), require_sri_for: %w(script))
        expect(csp.value).to eq("default-src 'self'; require-sri-for script")
      end

      it "allows style as a require-sri-src" do
        csp = ContentSecurityPolicy.new(default_src: %w('self'), require_sri_for: %w(style))
        expect(csp.value).to eq("default-src 'self'; require-sri-for style")
      end

      it "allows script and style as a require-sri-src" do
        csp = ContentSecurityPolicy.new(default_src: %w('self'), require_sri_for: %w(script style))
        expect(csp.value).to eq("default-src 'self'; require-sri-for script style")
      end

      it "includes prefetch-src" do
        csp = ContentSecurityPolicy.new(default_src: %w('self'), prefetch_src: %w(foo.com))
        expect(csp.value).to eq("default-src 'self'; prefetch-src foo.com")
      end

      it "includes navigate-to" do
        csp = ContentSecurityPolicy.new(default_src: %w('self'), navigate_to: %w(foo.com))
        expect(csp.value).to eq("default-src 'self'; navigate-to foo.com")
      end

      it "supports strict-dynamic" do
        csp = ContentSecurityPolicy.new({default_src: %w('self'), script_src: [ContentSecurityPolicy::STRICT_DYNAMIC], script_nonce: 123456})
        expect(csp.value).to eq("default-src 'self'; script-src 'strict-dynamic' 'nonce-123456' 'unsafe-inline'")
      end

      it "supports strict-dynamic and opting out of the appended 'unsafe-inline'" do
        csp = ContentSecurityPolicy.new({default_src: %w('self'), script_src: [ContentSecurityPolicy::STRICT_DYNAMIC], script_nonce: 123456, disable_nonce_backwards_compatibility: true })
        expect(csp.value).to eq("default-src 'self'; script-src 'strict-dynamic' 'nonce-123456'")
      end
    end
  end
end
