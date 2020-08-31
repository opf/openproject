---
sidebar_navigation:
  title: API settings
description: Settings for API functionality of OpenProject
robots: index, follow
keywords: API settings
---
# API system settings

In the API settings, you can selectively control whether foreign applications may access your OpenProject
API endpoints from within the browser. 

## Cross-Origin Resource Sharing (CORS)

To enable CORS headers being returned by the [OpenProject APIv3](https://docs.openproject.org/api/),
enable the check box on this page.

You will then have to enter the allowed values for the Origin header that OpenProject will allow access to.
This is necessary, since authenticated resources of OpenProject cannot be accessible to all origins with the `*` header value.

For more information on the concepts of Cross-Origin Resource Sharing (CORS), please see:

- [an overview of CORS from MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).
- [a tutorial on CORS by Auth0](https://auth0.com/blog/cors-tutorial-a-guide-to-cross-origin-resource-sharing/)
