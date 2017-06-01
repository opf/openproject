module Members
  class RoleFormCell < ::RailsCell
    include RemovedJsHelpersHelper

    options :row, :params, :roles

    def member
      model
    end

    def form_url
      url_for form_url_hash
    end

    def form_url_hash
      {
        controller: '/members',
        action: 'update',
        id: member.id,
        page: params[:page],
        per_page: params[:per_page]
      }
    end

    def role_checkbox(role)
      check_box_tag 'member[role_ids][]',
                    role.id,
                    member.roles.include?(role),
                    disabled: role_disabled?(role)
    end

    def role_disabled?(role)
      member
        .member_roles
        .detect { |mr| mr.role_id == role.id && !mr.inherited_from.nil? }
    end
  end
end
