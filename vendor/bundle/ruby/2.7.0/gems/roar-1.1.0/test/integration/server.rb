require "bundler/setup"
require "sinatra"
require "ostruct"
require "roar/json"
require "sinatra/multi_route"

require File.expand_path("../band_representer.rb", __FILE__)

class Band
  attr_reader :name, :label

  def name=(value)
    @name = value.upcase
  end

  def label=(value)
    @label = value.upcase
  end
end

def consume_band
  Band.new.
    extend(Integration::BandRepresenter).
    from_json(request.body.read)
end

get "/method" do
  "<method>get</method>"
end

post "/method" do
  "<method>post - #{request.body.read}</method>"
end

put "/method" do
  "<method>put - #{request.body.read}</method>"
end

delete "/method" do
  "<method>delete</method>"
end

patch "/method" do
  "<method>patch - #{request.body.read}</method>"
end

get '/deliberate-error' do
  raise 'this error was deliberate'
end

post "/bands" do
  #if request.content_type =~ /xml/
  body consume_band.to_json

  status 201
end

get '/bands' do
  [OpenStruct.new(:name => "Slayer", :label => "Canadian Maple"),
   OpenStruct.new(:name => "Nirvana", :label => "Sub Pop")]
    .extend(Integration::BandRepresenter.for_collection).to_json
end

put "/bands/strungout" do
  # DISCUSS: as long as we don't agree on what to return in PUT/PATCH, let's return an updated document.
  body consume_band.to_json
  #status 204
end

patch '/bands/strungout' do
  # DISCUSS: as long as we don't agree on what to return in PUT/PATCH, let's return an updated document.
  body consume_band.to_json
  #status 204
end

get "/bands/slayer" do
  OpenStruct.new(:name => "Slayer", :label => "Canadian Maple").
    extend(Integration::BandRepresenter).
    to_json
end

delete '/bands/metallica' do
  status 204
end

route :get, :delete, :patch, :post, :put, %r{/bands/nirvana/status([\d]*)_and_data} do
  status params[:captures]
  OpenStruct.new(:name => "Nirvana", :label => "Sub Pop").
    extend(Integration::BandRepresenter).
    to_json
end

route :get, :delete, :patch, :post, :put, %r{/bands/nirvana/status([\d]*)_no_data} do
  status params[:captures]
end


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

route :get, :post, :put, :delete, "/protected/bands/bodyjar" do
  protected!

  OpenStruct.new(:name => "Bodyjar").
    extend(Integration::BandRepresenter).
    to_json
end

route :get, :post, :put, :delete, "/cookies" do
  raise "No cookies!" unless request.env["HTTP_COOKIE"] == "Yumyum"
  %{{"name": "Bodyjar"}}
end

get "/ping" do
  "1"
end
