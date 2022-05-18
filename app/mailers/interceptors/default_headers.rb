module Interceptors
  class DefaultHeaders
    def self.delivering_email(mail)
      mail.headers(default_headers)
    end

    def self.default_headers
      {
        'X-Mailer' => 'OpenProject',
        'X-OpenProject-Host' => Setting.host_name,
        'X-OpenProject-Site' => Setting.app_title,
        'Precedence' => 'bulk',
        'Auto-Submitted' => 'auto-generated'
      }
    end
  end
end
