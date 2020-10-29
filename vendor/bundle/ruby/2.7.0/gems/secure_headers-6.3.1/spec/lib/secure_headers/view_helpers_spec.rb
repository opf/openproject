# frozen_string_literal: true
require "spec_helper"
require "erb"

class Message < ERB
  include SecureHeaders::ViewHelpers

  def self.template
<<-TEMPLATE
<% hashed_javascript_tag(raise_error_on_unrecognized_hash = true) do %>
  console.log(1)
<% end %>

<% hashed_style_tag do %>
  body {
    background-color: black;
  }
<% end %>

<% nonced_javascript_tag do %>
  body {
    console.log(1)
  }
<% end %>

<% nonced_style_tag do %>
  body {
    background-color: black;
  }
<% end %>

<script nonce="<%= content_security_policy_script_nonce %>">
  alert(1)
</script>

<style nonce="<%= content_security_policy_style_nonce %>">
  body {
    background-color: black;
  }
</style>

<%= nonced_javascript_include_tag "include.js", defer: true %>

<%= nonced_javascript_pack_tag "pack.js", "otherpack.js", defer: true %>

<%= nonced_stylesheet_link_tag "link.css", media: :all %>

<%= nonced_stylesheet_pack_tag "pack.css", "otherpack.css", media: :all %>

TEMPLATE
  end

  def initialize(request, options = {})
    @virtual_path = "/asdfs/index"
    @_request = request
    @template = self.class.template
    super(@template)
  end

  def capture(*args)
    yield(*args)
  end

  def content_tag(type, content = nil, options = nil, &block)
    content = if block_given?
      capture(block)
    end

    if options.is_a?(Hash)
      options = options.map { |k, v| " #{k}=#{v}" }
    end
    "<#{type}#{options}>#{content}</#{type}>"
  end

  def javascript_include_tag(*sources, **options)
    sources.map do |source|
      content_tag(:script, nil, options.merge(src: source))
    end
  end

  alias_method :javascript_pack_tag, :javascript_include_tag

  def stylesheet_link_tag(*sources, **options)
    sources.map do |source|
      content_tag(:link, nil, options.merge(href: source, rel: "stylesheet", media: "screen"))
    end
  end

  alias_method :stylesheet_pack_tag, :stylesheet_link_tag

  def result
    super(binding)
  end

  def request
    @_request
  end
end

class MessageWithConflictingMethod < Message
  def content_security_policy_nonce
    "rails-nonce"
  end
end

module SecureHeaders
  describe ViewHelpers do
    let(:app) { lambda { |env| [200, env, "app"] } }
    let(:middleware) { Middleware.new(app) }
    let(:request) { Rack::Request.new("HTTP_USER_AGENT" => USER_AGENTS[:chrome]) }
    let(:filename) { "app/views/asdfs/index.html.erb" }

    before(:all) do
      reset_config
      Configuration.default do |config|
        config.csp = {
          default_src: %w('self'),
          script_src: %w('self'),
          style_src: %w('self')
        }
      end
    end

    after(:each) do
      Configuration.instance_variable_set(:@script_hashes, nil)
      Configuration.instance_variable_set(:@style_hashes, nil)
    end

    it "raises an error when using hashed content without precomputed hashes" do
      expect {
        Message.new(request).result
      }.to raise_error(ViewHelpers::UnexpectedHashedScriptException)
    end

    it "raises an error when using hashed content with precomputed hashes, but none for the given file" do
      Configuration.instance_variable_set(:@script_hashes, filename.reverse => ["'sha256-123'"])
      expect {
        Message.new(request).result
      }.to raise_error(ViewHelpers::UnexpectedHashedScriptException)
    end

    it "raises an error when using previously unknown hashed content with precomputed hashes for a given file" do
      Configuration.instance_variable_set(:@script_hashes, filename => ["'sha256-123'"])
      expect {
        Message.new(request).result
      }.to raise_error(ViewHelpers::UnexpectedHashedScriptException)
    end

    it "adds known hash values to the corresponding headers when the helper is used" do
      begin
        allow(SecureRandom).to receive(:base64).and_return("abc123")

        expected_hash = "sha256-3/URElR9+3lvLIouavYD/vhoICSNKilh15CzI/nKqg8="
        Configuration.instance_variable_set(:@script_hashes, filename => ["'#{expected_hash}'"])
        expected_style_hash = "sha256-7oYK96jHg36D6BM042er4OfBnyUDTG3pH1L8Zso3aGc="
        Configuration.instance_variable_set(:@style_hashes, filename => ["'#{expected_style_hash}'"])

        # render erb that calls out to helpers.
        Message.new(request).result
        _, env = middleware.call request.env

        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/script-src[^;]*'#{Regexp.escape(expected_hash)}'/)
        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/script-src[^;]*'nonce-abc123'/)
        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/style-src[^;]*'nonce-abc123'/)
        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/style-src[^;]*'#{Regexp.escape(expected_style_hash)}'/)
      end
    end

    it "avoids calling content_security_policy_nonce internally" do
      begin
        allow(SecureRandom).to receive(:base64).and_return("abc123")

        expected_hash = "sha256-3/URElR9+3lvLIouavYD/vhoICSNKilh15CzI/nKqg8="
        Configuration.instance_variable_set(:@script_hashes, filename => ["'#{expected_hash}'"])
        expected_style_hash = "sha256-7oYK96jHg36D6BM042er4OfBnyUDTG3pH1L8Zso3aGc="
        Configuration.instance_variable_set(:@style_hashes, filename => ["'#{expected_style_hash}'"])

        # render erb that calls out to helpers.
        MessageWithConflictingMethod.new(request).result
        _, env = middleware.call request.env

        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/script-src[^;]*'#{Regexp.escape(expected_hash)}'/)
        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/script-src[^;]*'nonce-abc123'/)
        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/style-src[^;]*'nonce-abc123'/)
        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).to match(/style-src[^;]*'#{Regexp.escape(expected_style_hash)}'/)

        expect(env[ContentSecurityPolicyConfig::HEADER_NAME]).not_to match(/rails-nonce/)
      end
    end
  end
end
