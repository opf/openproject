#-- encoding: UTF-8
require 'uri'
require 'openid/extensions/sreg'
require 'openid/extensions/ax'
require 'openid/store/filesystem'

require File.dirname(__FILE__) + '/open_id_authentication/db_store'
require File.dirname(__FILE__) + '/open_id_authentication/mem_cache_store'
require File.dirname(__FILE__) + '/open_id_authentication/request'
require File.dirname(__FILE__) + '/open_id_authentication/timeout_fixes' if OpenID::VERSION == "2.0.4"

module OpenIdAuthentication
  OPEN_ID_AUTHENTICATION_DIR = RAILS_ROOT + "/tmp/openids"

  def self.store
    @@store
  end

  def self.store=(*store_option)
    store, *parameters = *([ store_option ].flatten)

    @@store = case store
    when :db
      OpenIdAuthentication::DbStore.new
    when :mem_cache
      OpenIdAuthentication::MemCacheStore.new(*parameters)
    when :file
      OpenID::Store::Filesystem.new(OPEN_ID_AUTHENTICATION_DIR)
    else
      raise "Unknown store: #{store}"
    end
  end

  self.store = :db

  class InvalidOpenId < StandardError
  end

  class Result
    ERROR_MESSAGES = {
      :missing      => "Sorry, the OpenID server couldn't be found",
      :invalid      => "Sorry, but this does not appear to be a valid OpenID",
      :canceled     => "OpenID verification was canceled",
      :failed       => "OpenID verification failed",
      :setup_needed => "OpenID verification needs setup"
    }

    def self.[](code)
      new(code)
    end

    def initialize(code)
      @code = code
    end

    def status
      @code
    end

    ERROR_MESSAGES.keys.each { |state| define_method("#{state}?") { @code == state } }

    def successful?
      @code == :successful
    end

    def unsuccessful?
      ERROR_MESSAGES.keys.include?(@code)
    end

    def message
      ERROR_MESSAGES[@code]
    end
  end

  # normalizes an OpenID according to http://openid.net/specs/openid-authentication-2_0.html#normalization
  def self.normalize_identifier(identifier)
    # clean up whitespace
    identifier = identifier.to_s.strip

    # if an XRI has a prefix, strip it.
    identifier.gsub!(/xri:\/\//i, '')

    # dodge XRIs -- TODO: validate, don't just skip.
    unless ['=', '@', '+', '$', '!', '('].include?(identifier.at(0))
      # does it begin with http?  if not, add it.
      identifier = "http://#{identifier}" unless identifier =~ /^http/i

      # strip any fragments
      identifier.gsub!(/\#(.*)$/, '')

      begin
        uri = URI.parse(identifier)
        uri.scheme = uri.scheme.downcase if uri.scheme # URI should do this
        identifier = uri.normalize.to_s
      rescue URI::InvalidURIError
        raise InvalidOpenId.new("#{identifier} is not an OpenID identifier")
      end
    end

    return identifier
  end

  # deprecated for OpenID 2.0, where not all OpenIDs are URLs
  def self.normalize_url(url)
    ActiveSupport::Deprecation.warn "normalize_url has been deprecated, use normalize_identifier instead"
    self.normalize_identifier(url)
  end

  protected
    def normalize_url(url)
      OpenIdAuthentication.normalize_url(url)
    end

    def normalize_identifier(url)
      OpenIdAuthentication.normalize_identifier(url)
    end

    # The parameter name of "openid_identifier" is used rather than the Rails convention "open_id_identifier"
    # because that's what the specification dictates in order to get browser auto-complete working across sites
    def using_open_id?(identity_url = nil) #:doc:
      identity_url ||= params[:openid_identifier] || params[:openid_url]
      !identity_url.blank? || params[:open_id_complete]
    end

    def authenticate_with_open_id(identity_url = nil, options = {}, &block) #:doc:
      identity_url ||= params[:openid_identifier] || params[:openid_url]

      if params[:open_id_complete].nil?
        begin_open_id_authentication(identity_url, options, &block)
      else
        complete_open_id_authentication(&block)
      end
    end

  private
    def begin_open_id_authentication(identity_url, options = {})
      identity_url = normalize_identifier(identity_url)
      return_to    = options.delete(:return_to)
      method       = options.delete(:method)
      
      options[:required] ||= []  # reduces validation later
      options[:optional] ||= []

      open_id_request = open_id_consumer.begin(identity_url)
      add_simple_registration_fields(open_id_request, options)
      add_ax_fields(open_id_request, options)
      redirect_to(open_id_redirect_url(open_id_request, return_to, method))
    rescue OpenIdAuthentication::InvalidOpenId => e
      yield Result[:invalid], identity_url, nil
    rescue OpenID::OpenIDError, Timeout::Error => e
      logger.error("[OPENID] #{e}")
      yield Result[:missing], identity_url, nil
    end

    def complete_open_id_authentication
      params_with_path = params.reject { |key, value| request.path_parameters[key] }
      params_with_path.delete(:format)
      open_id_response = timeout_protection_from_identity_server { open_id_consumer.complete(params_with_path, requested_url) }
      identity_url     = normalize_identifier(open_id_response.display_identifier) if open_id_response.display_identifier

      case open_id_response.status
      when OpenID::Consumer::SUCCESS
        profile_data = {}

        # merge the SReg data and the AX data into a single hash of profile data
        [ OpenID::SReg::Response, OpenID::AX::FetchResponse ].each do |data_response|
          if data_response.from_success_response( open_id_response )
            profile_data.merge! data_response.from_success_response( open_id_response ).data
          end
        end
        
        yield Result[:successful], identity_url, profile_data
      when OpenID::Consumer::CANCEL
        yield Result[:canceled], identity_url, nil
      when OpenID::Consumer::FAILURE
        yield Result[:failed], identity_url, nil
      when OpenID::Consumer::SETUP_NEEDED
        yield Result[:setup_needed], open_id_response.setup_url, nil
      end
    end

    def open_id_consumer
      OpenID::Consumer.new(session, OpenIdAuthentication.store)
    end

    def add_simple_registration_fields(open_id_request, fields)
      sreg_request = OpenID::SReg::Request.new
      
      # filter out AX identifiers (URIs)
      required_fields = fields[:required].collect { |f| f.to_s unless f =~ /^https?:\/\// }.compact
      optional_fields = fields[:optional].collect { |f| f.to_s unless f =~ /^https?:\/\// }.compact
      
      sreg_request.request_fields(required_fields, true) unless required_fields.blank?
      sreg_request.request_fields(optional_fields, false) unless optional_fields.blank?
      sreg_request.policy_url = fields[:policy_url] if fields[:policy_url]
      open_id_request.add_extension(sreg_request)
    end
    
    def add_ax_fields( open_id_request, fields )
      ax_request = OpenID::AX::FetchRequest.new
      
      # look through the :required and :optional fields for URIs (AX identifiers)
      fields[:required].each do |f|
        next unless f =~ /^https?:\/\//
        ax_request.add( OpenID::AX::AttrInfo.new( f, nil, true ) )
      end

      fields[:optional].each do |f|
        next unless f =~ /^https?:\/\//
        ax_request.add( OpenID::AX::AttrInfo.new( f, nil, false ) )
      end
      
      open_id_request.add_extension( ax_request )
    end
        
    def open_id_redirect_url(open_id_request, return_to = nil, method = nil)
      open_id_request.return_to_args['_method'] = (method || request.method).to_s
      open_id_request.return_to_args['open_id_complete'] = '1'
      open_id_request.redirect_url(root_url, return_to || requested_url)
    end

    def requested_url
      relative_url_root = self.class.respond_to?(:relative_url_root) ?
        self.class.relative_url_root.to_s :
        request.relative_url_root
      "#{request.protocol}#{request.host_with_port}#{relative_url_root}#{request.path}"
    end

    def timeout_protection_from_identity_server
      yield
    rescue Timeout::Error
      Class.new do
        def status
          OpenID::FAILURE
        end

        def msg
          "Identity server timed out"
        end
      end.new
    end
end
