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

          formatItems = function (item, container, query) {
            var match = item.name.toUpperCase().indexOf(query.term.toUpperCase()),
            tl = query.term.length,
            markup = [];

            if (match < 0) {
              return "<span data-value='" + item.id + "'>" + item.name + "</span>";
            }

            markup.push(item.name.substring(0, match));
            markup.push("<span class='select2-match' data-value='" + item.id + "'>");
            markup.push(item.name.substring(match, match + tl));
            markup.push("</span>");
            markup.push(item.name.substring(match + tl, item.name.length));
            return markup.join("")
          }

          formatItemSelection = function (item) {
            return item.name;
          }

          $(fakeInput).select2({
            minimumInputLength: 1,
            ajax: {
                url: $(fakeInput).attr("data-ajaxURL"),
                dataType: 'json',
                quietMillis: 500,
                contentType: "application/json",
                data: function (term, page) {
                    return {
                        q: term, //search term
                        page_limit: 10, // page size
                        page: page, // current page number
                        id: fakeInput.attr("data-projectId") // current project id
                    };
                },
                results: function (data, page) {

                    active_items = []
                    data.results.items.each(function (e) {
                      active_items.push(e);
                    });
                    return {'results': active_items, 'more': data.results.more};
                }
            },
            formatResult: formatItems,
            formatSelection: formatItemSelection
          });
          $(elem).hide();
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
});

