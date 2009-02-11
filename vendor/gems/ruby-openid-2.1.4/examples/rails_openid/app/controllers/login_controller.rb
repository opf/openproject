# Controller for handling the login, logout process for "users" of our
# little server.  Users have no password.  This is just an example.

require 'openid'

class LoginController < ApplicationController

  layout 'server'

  def base_url
    url_for(:controller => 'login', :action => nil, :only_path => false)
  end

  def index
    response.headers['X-XRDS-Location'] = url_for(:controller => "server",
                                                  :action => "idp_xrds",
                                                  :only_path => false)
    @base_url = base_url
    # just show the login page
  end

  def submit
    user = params[:username]

    # if we get a user, log them in by putting their username in
    # the session hash.
    unless user.nil?
      session[:username] = user unless user.nil?
      session[:approvals] = []
      flash[:notice] = "Your OpenID URL is <b>#{base_url}user/#{user}</b><br/><br/>Proceed to step 2 below."
    else
      flash[:error] = "Sorry, couldn't log you in. Try again."
    end
    
    redirect_to :action => 'index'
  end

  def logout
    # delete the username from the session hash
    session[:username] = nil
    session[:approvals] = nil
    redirect_to :action => 'index'
  end

end
