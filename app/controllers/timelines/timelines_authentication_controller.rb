class Timelines::TimelinesAuthenticationController < ApplicationController
  unloadable
  helper :timelines

  before_filter :require_login
  accept_key_auth :index

  def index
    respond_to do |format|
      format.html
      format.api
    end
  end
end
