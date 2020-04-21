class SeafileController < ApplicationController
  include ReverseProxy::Controller

  def index
    reverse_proxy "https://seafile-demo.de", headers: { "Authorization" => "Token eea2fc92262ea156d8bf3bec8e945e854b5e608f" } do
    end
  end
end