jQuery(function ($) {

  // Toggle selector for new/edit webhooks projects
  $('input[name="webhook[project_ids]"]').change(function(){
    $('.webhooks--selected-project-ids').prop('disabled', $(this).val() === 'all');
  });

  $('input[name="webhook[type_ids]"]').change(function(){
    $('.webhooks--selected-type-ids').prop('disabled', $(this).val() === 'all');
  });

});