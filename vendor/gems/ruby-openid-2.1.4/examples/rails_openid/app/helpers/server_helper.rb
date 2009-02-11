
module ServerHelper

  def url_for_user
    url_for :controller => 'user', :action => session[:username]
  end

end

