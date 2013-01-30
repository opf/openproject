jQuery(document).ready(function($) {
  var load_cb, memberstab, update_cb;
  init_members_cb = function () {
    $("#members_add_form select.select2-select").each(function (ix, elem){
      if (!$.isEmptyObject(elem.siblings('div.select2-select.select2-container'))) {
        setTimeout (function () {
          var attributes, allowed, currentName, fakeInput;
          attributes = {}
          allowed = ["title", "placeholder"];

          for(var i = 0; i < $(elem).get(0).attributes.length; i++) {
            currentName = $(elem).get(0).attributes[i].name;
            if(currentName.indexOf("data-") == 0 || $.inArray(currentName, allowed)); //only ones starting with data-
            attributes[currentName] = $(elem).attr(currentName);
          }
          fakeInput = $(elem).after("<input type='hidden'></input>").siblings(":input:first");
          fakeInput.attr(attributes);
          $(fakeInput).select2({
            minimumInputLength: 1,
            ajax: {
                url: $(fakeInput).attr("data-ajaxURL"),
                dataType: 'json',
                quietMillis: 100,
                contentType: "application/json",
                data: function (term, page) {
                    return {
                        q: term, //search term
                        page_limit: 10, // page size
                        page: page, // page number
                        id: fakeInput.attr("data-projectId") // current project id
                    };
                },
                results: function (data, page) {

                    // notice we return the value of more so Select2 knows if more results can be loaded
                    active_principals = []
                    data.results.principals.each(function (e) {
                      if (e.active === true) {
                        active_principals.push(e);
                      }
                    });
                    return {'results': active_principals, 'more': data.results.more};
                }
            },
            formatResult: formatPrincipal, // omitted for brevity, see the source of this page
            formatSelection: formatPrincipalSelection
          });
          // $(elem).hide();
        }, 0);
      }
    });
  }
  memberstab = $('#tab-members').first();
  if ((memberstab != null) && (memberstab.hasClass("selected"))) {
    init_members_cb();
  } else {
    memberstab.click(init_members_cb);
  }

  formatPrincipal = function (principal) {
    var markup = "<span class='select2-match' data-value='" + principal.id + "'>" + principal.name + "</span>";
    return markup;
  }
  formatPrincipalSelection = function (principal) {
    return principal.name;
  }

});