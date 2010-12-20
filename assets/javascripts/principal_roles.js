var principal_roles = {
	init: function(){
		principal_roles.set_table_visibility();
		principal_roles.set_role_selection_visibility();
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

	set_role_selection_visibility: function(){
		$$('.principal_role_option').each(function(element){
			if($$('.assigned_global_role_' + element.down('input').value).length > 0){
				//element.hide();
			}
			else{
				//element.show();
			}
			//element.checked = false;
		})
	},

	role_already_assigned: function(){
		return ($$('.assigned_global_role_' + element.down('input').value).length > 0)
	}
};

document.observe('dom:loaded', principal_roles.init);

Ajax.Responders.register({
  onComplete: principal_roles.init
});