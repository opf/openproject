module Interceptors
  module DefaultHeaders
    module_function

    def delivering_email(mail)
      mail.headers(default_headers)
    end

    def default_headers
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
