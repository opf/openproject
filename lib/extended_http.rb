#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module ExtendedHTTP
  # Use this in response to an HTTP POST (or PUT), telling the client where the
  # new resource is.  Works just like redirect_to, but sends back a 303 (See
  # Other) status code.  Redirects should be used to tell the client to repeat
  # the same request on a different resource, and see_other when we want the
  # client to follow a POST (on this resource) with a GET (to the new resource).
  #
  # This is especially useful for successful create actions.
  def see_other(options = {})
    if options.is_a?(Hash)
      redirect_to options.merge(:status=>:see_other)
    else
      redirect_to options, :status=>:see_other
    end
  end

  # Use this in response to an HTTP PUT (or POST), telling the client that
  # everything went well and the desired change was performed successfully.
  #
  # This is especially useful for successful update actions.
  def no_content
    render :text => '', :status => :no_content
  end
end
