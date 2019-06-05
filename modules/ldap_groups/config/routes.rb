OpenProject::Application.routes.draw do
  namespace 'ldap_groups' do
    resources :synchronized_groups,
              param: :ldap_group_id,
              only: %i(new index create show destroy) do

      member do
        # Destroy warning
        get 'destroy_info'
      end

      collection do
        # Plugin settings update
        post 'update_settings', action: 'update_settings'
      end
    end
  end
end