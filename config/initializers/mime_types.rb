#-- encoding: UTF-8
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
# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::SET << Mime::CSV unless Mime::SET.include?(Mime::CSV)

Mime::Type.register 'application/pdf', :pdf unless Mime::Type.lookup_by_extension(:pdf)
Mime::Type.register 'image/png', :png unless Mime::Type.lookup_by_extension(:png)
