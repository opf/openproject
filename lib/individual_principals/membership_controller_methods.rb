module IndividualPrincipals
  module MembershipControllerMethods
    def update
      update_or_create(request.patch?, :notice_successful_update)
    end

    def create
      update_or_create(request.post?, :notice_successful_create)
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

    def update_or_create(save_record, message)
      @membership = params[:id].present? ? Member.find(params[:id]) : Member.new(principal: @individual_principal, project: nil)

      result = ::Members::EditMembershipService
                   .new(@membership, save: save_record, current_user: current_user)
                   .call(attributes: permitted_params.membership)

      if result.success?
        flash[:notice] = I18n.t(message)
      else
        flash[:error] = result.errors.full_messages.join("\n")
      end

      redirect_to edit_polymorphic_path(@individual_principal, tab: redirected_to_tab(@membership))
    end
  end
end
