var principal_roles = {
	init: function(){
		principal_roles.set_table_visibility();
		principal_roles.set_available_roles_visibility();
	},

	set_table_visibility: function(){
		if ($$('#table_principal_roles_body tr').length > 0){
			$('table_principal_roles').show();
			$('no_data').hide();
		}
		else
		{
			$('table_principal_roles').hide();
			$('no_data').show();
		}
	},

	set_available_roles_visibility: function(){
		if ($$('.principal_role_option').length > 0){
			$('additional_principal_roles').show();
			$('no_additional_principal_roles').hide();
		}
		else
		{
			$('additional_principal_roles').hide();
			$('no_additional_principal_roles').show();
		}
	},

	role_already_assigned: function(){
		return ($$('.assigned_global_role_' + element.down('input').value).length > 0)
	}
};

document.observe('dom:loaded', principal_roles.init);

Ajax.Responders.register({
  onComplete: principal_roles.init
});