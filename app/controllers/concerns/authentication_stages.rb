module Concerns
  module AuthenticationStages
    def stage_success
      identifier, _, _ = session[:authentication_stages].first

      if identifier.to_s == params[:stage]
        session[:authentication_stages] = session[:authentication_stages].drop(1)

        successful_authentication User.find(session[:authenticated_user_id]), reset_stages: false
      else
        flash[:error] = "Expected to finish authentication stage '#{identifier}', but '#{params[:stage]}' returned."

        redirect_to signin_path
      end
    end

    def stage_failure
      flash[:error] = flash[:error] || "Authentication stage '#{params[:stage]}' failed."

      redirect_to signin_path
    end

    private

    def authentication_stages
      if !OpenProject::Authentication::Stage.stages.empty?
        if session.include?(:authentication_stages)
          session[:authentication_stages]
        else
          session[:authentication_stages] = OpenProject::Authentication::Stage.stages.dup
        end
      else
        []
      end
    end
  end
end
