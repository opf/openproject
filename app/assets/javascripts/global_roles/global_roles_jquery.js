//-- copyright
// OpenProject is a project management system.
//
// Copyright (C) 2010-2013 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

//= require global_roles/principal_roles

(function ($, undefined) {
  var global_roles = {
		init: function(){
			global_roles.toggle_forms_on_click();
			global_roles.activation_and_visibility_based_on_checked($('#global_role'));
		},

		toggle_forms_on_click: function(){
			$('#global_role').on("click", global_roles.toggle_forms);
		},

		toggle_forms: function(event){
			global_roles.activation_and_visibility_based_on_checked(this)
		},

		activation_and_visibility_based_on_checked: function(element){
			if($(element).attr("checked")){
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
			$('#global_attributes').show();
			$('#global_permissions').show();
		},

		show_member_forms: function(){
			$('#member_attributes').show();
			$('#member_permissions').show();
		},

		hide_global_forms: function(){
			$('#global_attributes').hide();
			$('#global_permissions').hide();
		},

		hide_member_forms: function(){
			$('#member_attributes').hide();
			$('#member_permissions').hide();
		},

		enable_global_forms: function(){
			$('#global_attributes input, #global_attributes input, #global_permissions input').each(function (ix, el) {
				global_roles.enable_element(el);
			});
		},

		enable_member_forms: function(){
		 	$('#member_attributes input, #member_attributes input, #member_permissions input').each(function (ix, el) {
		 		global_roles.enable_element(el);	
		 	});
		},

		enable_element: function(element){
			element.enable();
		},

		disable_global_forms: function(){
			$('#global_attributes input, #global_attributes input, #global_permissions input').each(function (ix, el) {
				global_roles.disable_element(el);
			});
		},

		disable_member_forms: function(){
			$('#member_attributes input, #member_attributes input, #member_permissions input').each(function (ix, el) {
				global_roles.disable_element(el);
			});
		},

		disable_element: function(element){
			element.disable();
		}
  }
	$(document).ready(global_roles.init);
}(jQuery));
