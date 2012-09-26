Event.observe(window,'load',function() {
  /* 
  If we're viewing a tag or branch, don't display it in the
  revision box
  */
  var branch_selected = $('branch') && $('rev').getValue() == $('branch').getValue();
  var tag_selected = $('tag') && $('rev').getValue() == $('tag').getValue();
  if (branch_selected || tag_selected) {
    $('rev').setValue('');
  }

  /* 
  Copy the branch/tag value into the revision box, then disable
  the dropdowns before submitting the form
  */
  $$('#branch,#tag').each(function(e) {
    e.observe('change',function(e) {
      $('rev').setValue(e.element().getValue());
      $$('#branch,#tag').invoke('disable');
      e.element().parentNode.submit();
      $$('#branch,#tag').invoke('enable');
    });
  });

  /*
  Disable the branch/tag dropdowns before submitting the revision form
  */
  $('rev').observe('keydown', function(e) {
    if (e.keyCode == 13) {
      $$('#branch,#tag').invoke('disable');
      e.element().parentNode.submit();
      $$('#branch,#tag').invoke('enable');
    }
  });
})
