module Concerns
  module AuthenticationStages
    def stage_success
      stage = session[:authentication_stages].first

      if stage.to_s == params[:stage]
        session[:authentication_stages] = session[:authentication_stages].drop(1)

        successful_authentication User.find(session[:authenticated_user_id]), reset_stages: false
      else
        flash[:error] = "Expected to finish authentication stage '#{stage}', but '#{params[:stage]}' returned."

        redirect_to signin_path
      end
    end

    def stage_failure
      flash[:error] = flash[:error] || "Authentication stage '#{params[:stage]}' failed."

      redirect_to signin_path
    end

    private

    def authentication_stages(after_activation: false, reset: true)
      if !OpenProject::Authentication::Stage.stages.empty?
        session.delete :authentication_stages if reset

        if session.include?(:authentication_stages)
          OpenProject::Authentication::Stage.find_all session[:authentication_stages]
        else
          stages = OpenProject::Authentication::Stage
            .stages
            .select { |s| s.run_after_activation? || !after_activation }

          session[:authentication_stages] = stages.map(&:identifier)

          stages
        end
      else
        []
      end
    end
  end
end
