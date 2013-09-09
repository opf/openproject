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

# Register interceptors defined in app/mailers/user_mailer.rb
# Do this here, so they aren't registered multiple times due to reloading in development mode.

UserMailer.register_interceptor(DefaultHeadersInterceptor)
UserMailer.register_interceptor(RemoveSelfNotificationsInterceptor)
# following needs to be the last interceptor
UserMailer.register_interceptor(DoNotSendMailsWithoutReceiverInterceptor)
