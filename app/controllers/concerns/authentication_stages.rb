module Concerns
  module AuthenticationStages
    def stage_success
      stage = session[:authentication_stages].first

      if stage.to_s == params[:stage]
        if params[:secret] == stage_secrets[stage]
          session[:authentication_stages] = session[:authentication_stages].drop(1)

          successful_authentication User.find(session[:authenticated_user_id]), reset_stages: false
        else
          flash[:error] = I18n.t :notice_auth_stage_verification_error, stage: stage

          redirect_to signin_path
        end
      else
        flash[:error] = I18n.t(
          :notice_auth_stage_wrong_stage,
          expected: stage,
          actual: params[:stage]
        )

        redirect_to signin_path
      end
    end

    def stage_failure
      flash[:error] = flash[:error] || I18n.t(:notice_auth_stage_error, stage: params[:stage])

      redirect_to signin_path
    end

    private

    def authentication_stages(after_activation: false, reset: true)
      if !OpenProject::Authentication::Stage.stages.empty?
        session.delete [:authentication_stages, :stage_secrets, :back_url] if reset

        if session.include?(:authentication_stages)
          lookup_authentication_stages
        else
          init_authentication_stages after_activation: after_activation
        end
      else
        []
      end
    end

    def lookup_authentication_stages
      OpenProject::Authentication::Stage.find_all session[:authentication_stages]
    end

    def init_authentication_stages(after_activation:)
      stages = OpenProject::Authentication::Stage
        .stages
        .select { |s| s.active? }
        .select { |s| s.run_after_activation? || !after_activation }

      session[:authentication_stages] = stages.map(&:identifier)
      session[:stage_secrets] = session[:authentication_stages]
        .map { |ident| [ident, stage_secret(ident)] }
        .to_h

      # Remember back_url from params since we're redirecting
      # but don't use the referer
      session[:back_url] = params[:back_url]

      stages
    end

    def stage_secrets
      Hash(session[:stage_secrets])
    end

    def stage_secret(ident)
      SecureRandom.hex(16)
    end
  end
end
