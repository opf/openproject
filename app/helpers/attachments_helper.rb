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
    if str.respond_to?(:force_encoding)
      str.force_encoding('UTF-8')
      return str if str.valid_encoding?
    else
      return str if /\A[\r\n\t\x20-\x7e]*\Z/n.match(str) # for us-ascii
    end
    
    begin
      Iconv.conv('UTF-8//IGNORE', 'UTF-8', str + '  ')[0..-3]
    rescue Iconv::InvalidEncoding
      # "UTF-8//IGNORE" is not supported on some OS
      str
    end
  end
end
