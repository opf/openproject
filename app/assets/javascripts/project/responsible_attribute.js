jQuery(document).ready(function($) {
  $("#project_responsible_id").autocomplete({
    ajax: {
      null_element: {id: -1, name: I18n.t("js.filter.noneElement")},
      data: function (term, page) {
        return {
          q: term, //search term
          page_limit: 10, // page size
          page: page, // current page number
          id: $("#project_responsible_id").attr("data-projectId")
        };
      }
    }
  });
});
