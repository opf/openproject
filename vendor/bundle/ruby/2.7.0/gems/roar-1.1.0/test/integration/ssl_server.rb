require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'sinatra/multi_route'

name = "/C=US/ST=SomeState/L=SomeCity/O=Organization/OU=Unit/CN=localhost"
ca   = OpenSSL::X509::Name.parse(name)
key = OpenSSL::PKey::RSA.new(1024)
crt = OpenSSL::X509::Certificate.new
crt.version = 2
crt.serial  = 1
crt.subject = ca
crt.issuer = ca
crt.public_key = key.public_key
crt.not_before = Time.now
crt.not_after  = Time.now + 1 * 365 * 24 * 60 * 60 # 1 year
crt.sign(key, OpenSSL::Digest::SHA1.new)
webrick_options = {
    :Port               => 8443,
    :SSLEnable          => true,
    :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate     => crt,
    :SSLPrivateKey      => key,
    :SSLCertName        => [[ "CN", WEBrick::Utils::getservername ]],
}

class SslServer < Sinatra::Base
  register Sinatra::MultiRoute

  get '/ping' do
    "1"
  end

  route :get, :post, :put, :delete, "/bands/bodyjar" do
    %{{"name": "Bodyjar"}}
  end

  # FIXME: redundant with server.rb.
  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'password']
    end
  end

  get "/protected" do
    protected!

    %{{"name": "Bodyjar"}}
  end
end
server = ::Rack::Handler::WEBrick

server.run(SslServer, webrick_options)
