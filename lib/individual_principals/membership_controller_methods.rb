module IndividualPrincipals
  module MembershipControllerMethods
    extend ActiveSupport::Concern

    included do
      before_action :find_membership, only: %i[update destroy]
    end

    def create
      membership_params = permitted_params.membership.merge(principal: @individual_principal)
      call = ::Members::CreateService
        .new(user: current_user)
        .call(membership_params)

      respond_with_service_call call, message: :notice_successful_create
    end

    def update
      call = ::Members::UpdateService
        .new(model: @membership, user: current_user)
        .call(permitted_params.membership)

      respond_with_service_call call, message: :notice_successful_update
    end

    def destroy
      @membership = @individual_principal.memberships.find(params[:id])
      tab = redirected_to_tab(@membership)

      if @membership.deletable? && request.delete?
        @membership.destroy
        @membership = nil

        flash[:notice] = I18n.t(:notice_successful_delete)
      end

      redirect_to edit_polymorphic_path(@individual_principal, tab: tab)
    end

    private

    def find_membership
      @membership = Member.visible(current_user).find(params[:id])
    end

    def respond_with_service_call(call, message:)
      if call.success?
        flash[:notice] = I18n.t(message)
      else
        flash[:error] = call.errors.full_messages.join("\n")
      end

      redirect_to edit_polymorphic_path(@individual_principal, tab: redirected_to_tab(call.result))
    end
  end
end
