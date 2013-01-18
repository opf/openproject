#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module AttachmentsHelper
  # Displays view/delete links to the attachments of the given object
  # Options:
  #   :author -- author names are not displayed if set to false
  def link_to_attachments(container, options = {})
    options.assert_valid_keys(:author)

    if container.attachments.any?
      options = {:deletable => container.attachments_deletable?, :author => true}.merge(options)
      render :partial => 'attachments/links', :locals => {:attachments => container.attachments, :options => options}
    end
  end

  def to_utf8_for_attachments(str)
    forced_str = str.dup
    forced_str.force_encoding('UTF-8')
    return forced_str if forced_str.valid_encoding?

    str.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '') # better :replace => '?'
  end
end
