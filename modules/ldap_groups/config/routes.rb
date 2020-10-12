OpenProject::Application.routes.draw do
  namespace 'ldap_groups' do

    resources :synchronized_filters,
              param: :ldap_filter_id,
              except: %i(index) do

      member do
        # Extract groups from filter
        get 'synchronize'

        # Destroy warning
        get 'destroy_info'
      end
    end

    resources :synchronized_groups,
              param: :ldap_group_id,
              only: %i(new index create show destroy) do

      member do
        # Destroy warning
        get 'destroy_info'
      end
    end
  end
end