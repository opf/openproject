class PermittedParams < Struct.new(:params, :user)
  # This class intends to provide a method for all params hashes comming from the
  # client and that are used for mass assignment.
  #
  # As such, please make it a deliberate decission to whitelist attributes.
  #
  # This implementation depends on the strong_parameters gem. For further
  # information see here: https://github.com/rails/strong_parameters
  #
  #
  # A method should look like the following:
  #
  # def name_of_the_params_key_referenced
  #   params.require(:name_of_the_params_key_referenced).permit(list_of_whitelisted_params)
  # end
  #
  #
  # A controller could use a permitted_params method like this
  #
  # model_instance.attributes = permitted_params.name_of_the_params_key_referenced
  #
  # instead of doing something like this which will not work anymore once the
  # model is protected:
  #
  # model_instance.attributes = params[:name_of_the_params_key_referenced]
  #
  #
  # A model will need the following module included in order to be protected by
  # strong_params
  #
  # include ActiveModel::ForbiddenAttributesProtection
end

