// we cannot just use print as the handler
function print_wiki_handler() {
  print();
}

jQuery(document.body).on('click', '.op-wiki-context-print', print_wiki_handler);

