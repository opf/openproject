tinyMCE.init({
  // General options
  mode : "none",
  theme : "advanced",
  plugins : "visualblocks, autolink,lists,spellchecker,style,table,advhr,advimage,advlink,template,iespell,inlinepopups,insertdatetime,media,searchreplace,contextmenu,paste,noneditable,visualchars,nonbreaking,xhtmlxtras",

  // Theme options
  theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,formatselect,|,cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,image,cleanup,visualblocks,code,|,insertdate,inserttime",
  theme_advanced_buttons2 : "forecolor,backcolor,|,tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,iespell,media,advhr,|,spellchecker,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,|,insertfile,insertimage",
  theme_advanced_toolbar_location : "top",
  theme_advanced_toolbar_align : "left",
  theme_advanced_statusbar_location : "bottom",
  theme_advanced_resizing : true,
  add_form_submit_trigger : true,

  // Skin options
  skin : "o2k7",
  skin_variant : "silver"

  // Example content CSS (should be your site CSS)
  //content_css : "css/example.css",
});