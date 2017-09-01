module Concerns
  ##
  # If OPENPROJECT_AUTH__SOURCE__SSO_HEADER and OPENPROJECT_AUTH__SOURCE__SSO_SECRET are
  # configured OpenProject will login the user given in the HTTP header with the given name
  # together with the secret in the form of `login:$secret`.
  module AuthSourceSSO
    def find_current_user
      user = super

      return user if user || sso_in_progress!

      if login = read_sso_login
        user = find_user_from_auth_source(login) || create_user_from_auth_source(login)

        handle_sso_for! user, login
      end
    end

    def read_sso_login
      return nil unless header_name && secret

      login, given_secret = String(request.headers[header_name]).split(":")

      login if valid_credentials? login, given_secret
    end

    def sso_config
      @sso_config ||= OpenProject::Configuration.auth_source_sso.try(:with_indifferent_access)
    end

    def header_name
      sso_config && sso_config[:header]
    end

    def secret
      sso_config && sso_config[:secret]
    end

    def valid_credentials?(login, secret)
      !invalid_credentials?(login, secret)
    end

    def invalid_credentials?(login, secret)
      if secret != self.secret.to_s
        Rails.logger.error(
          "Secret contained in auth source SSO header not valid. " +
          "(#{header_name}: #{request.headers[header_name]})"
        )

        true
      elsif login.nil?
        Rails.logger.error(
          "No login contained in auth source SSO header. " +
          "(#{header_name}: #{request.headers[header_name]})"
        )

        true
      end
    end

    def find_user_from_auth_source(login)
      User.where(login: login).where.not(auth_source_id: nil).first
    end

    def create_user_from_auth_source(login)
      if attrs = AuthSource.find_user(login)
        # login is both safe and protected in chilis core code
        # in case it's intentional we keep it that way
        user = User.new attrs.except(:login)
        user.login = login
        user.language = Setting.default_language

        save_user! user

        user
      end
    end

    def save_user!(user)
      if user.save
        user.reload

        if logger && user.auth_source
          logger.info(
            "User '#{user.login}' created from external auth source: " +
            "#{user.auth_source.type} - #{user.auth_source.name}"
          )
        end
      end
    end

    def sso_in_progress!
      sso_failure_in_progress! || session[:auth_source_registration]
    end

    def sso_failure_in_progress!
      failure = session[:auth_source_sso_failure]

      if failure
        if failure[:ttl] > 0
          session[:auth_source_sso_failure] = failure.merge(ttl: failure[:ttl] - 1)
        else
          session.delete :auth_source_sso_failure

          nil
        end
      end
    end

    def sso_login_failed?(user)
      user.nil? || user.new_record? || !user.active?
    end

    def handle_sso_for!(user, login)
      if sso_login_failed?(user)
        handle_sso_failure! user, login
      else # valid user
        handle_sso_success user
      end
    end

    def handle_sso_success(user)
      session[:user_id] = user.id

      user
    end

    def handle_sso_failure!(user, login)
      session[:auth_source_sso_failure] = {
        user: user,
        login: login,
        back_url: request.base_url + request.original_fullpath,
        ttl: 1
      }

      redirect_to sso_failure_path
    end
  end
end
