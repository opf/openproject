# Register interceptors defined in app/mailers/user_mailer.rb
# Do this here, so they aren't registered multiple times due to reloading in development mode.

UserMailer.register_interceptor(DefaultHeadersInterceptor)
UserMailer.register_interceptor(RemoveSelfNotificationsInterceptor)
# following needs to be the last interceptor
UserMailer.register_interceptor(DoNotSendMailsWithoutReceiverInterceptor)
