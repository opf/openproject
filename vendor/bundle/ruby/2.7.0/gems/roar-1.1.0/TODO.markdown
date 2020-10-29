# 1.0

* merge client errors request
* simpler link for JSON-API?
* remove HttpVerbs deprecations

* Hyperlink representers => decrators. test hash representer with decorator (rpr)


* Add proxies, so nested models can be lazy-loaded.
* move #prepare_links! call to #_links or something so it doesn't need to be called in #serialize.
* abstract ::links_definition_options and move them out of the generic representers (JSON, XML).
* work on HAL-Object