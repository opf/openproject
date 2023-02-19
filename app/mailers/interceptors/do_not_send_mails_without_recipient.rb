module Interceptors
  module DoNotSendMailsWithoutRecipient
    module_function

    def delivering_email(mail)
      receivers = [mail.to, mail.cc, mail.bcc]
      # the above fields might be empty arrays (if entries have been removed
      # by another interceptor) or nil, therefore checking for blank?
      mail.perform_deliveries = false if receivers.all?(&:blank?)
    end
  end
end
