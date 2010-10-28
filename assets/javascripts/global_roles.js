var global_roles = {
	init: function(){
		global_roles.toggle_forms_on_click();
		global_roles.activation_and_visibility_based_on_checked($('global_role'));
	},

	toggle_forms_on_click: function(){
		$('global_role').observe("click", global_roles.toggle_forms);
	},

	toggle_forms: function(event){
		global_roles.activation_and_visibility_based_on_checked(this)
	},

	activation_and_visibility_based_on_checked: function(element){
		if($(element).checked){
			global_roles.show_global_forms();
			global_roles.hide_member_forms();
			global_roles.enable_global_forms();
			global_roles.disable_member_forms();
		}
		else{
			global_roles.show_member_forms();
			global_roles.hide_global_forms();
			global_roles.disable_global_forms();
			global_roles.enable_member_forms();
		}
	},

	show_global_forms: function(){
		$('global_attributes').show();
		$('global_permissions').show();
	},

	show_member_forms: function(){
		$('member_attributes').show();
		$('member_permissions').show();
	},

	hide_global_forms: function(){
		$('global_attributes').hide();
		$('global_permissions').hide();
	},

	hide_member_forms: function(){
		$('member_attributes').hide();
		$('member_permissions').hide();
	},

	enable_global_forms: function(){
		$$('#global_attributes input, #global_attributes input').each(global_roles.enable_element);
		$$('#global_permissions input').each(global_roles.enable_element);
	},

	enable_member_forms: function(){
	 	$$('#member_attributes input, #member_attributes input').each(global_roles.enable_element);
	 	$$('#member_permissions input').each(global_roles.enable_element);
	},

	enable_element: function(element){
		element.enable();
	},

	disable_global_forms: function(){
		$$('#global_attributes input, #global_attributes input').each(global_roles.disable_element);
		$$('#global_permissions input').each(global_roles.disable_element);;
	},

	disable_member_forms: function(){
		$$('#member_attributes input, #member_attributes input').each(global_roles.disable_element);;
		$$('#member_permissions input').each(global_roles.disable_element);;
	},

	disable_element: function(element){
		element.disable();
	}
};
document.observe("dom:loaded", global_roles.init);