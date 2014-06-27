 
angular.module('openproject.hal')

.factory('HALAPIResource', function HALAPIResource() {
  'use strict';

  var HALAPIResource = {
    parseApiaryResponse: function(json) {
      // Apiary mock response isn't valid json so i'm mocking the mock:/ TODO: Get this from a file
      var mockWorkPackageResponse = "{    \"_type\": \"WorkPackage\",    \"_links\": {        \"self\": {            \"href\": \"https://openproject.org/api/v3/work_packages/1\",            \"title\": \"quis numquam qui voluptatum quia praesentium blanditiis nisi\"        }    },    \"_embedded\": {        \"activities\": [            {                \"_type\": \"Activity\",                \"_links\": {                    \"self\": {                        \"href\": \"https://openproject.org/api/v3/activity/1\",                        \"title\": \"Priority changed from High to Low\"                    },                    \"workPackage\": {                        \"href\": \"https://openproject.org/api/v3/work_packages/1\",                        \"title\": \"quis numquam qui voluptatum quia praesentium blanditiis nisi\"                    },                    \"user\": {                        \"href\": \"https://openproject.org/api/v3/users/1\",                        \"title\": \"John Sheppard - admin\"                    }                },                \"id\": 1,                \"userId\": 1,                \"userName\": \"OpenProject Admin\",                \"userLogin\": \"admin\",                \"userMail\": \"admin@example.net\",                \"notes\": \"Lorem ipsum dolor sit amet\",                \"details\": [                    \"Priority changed from High to Low\"                ],                \"createdAt\": \"2014-05-21T08: 51: 20Z\",                \"version\": 31            }        ],        \"watchers\": [            {                \"_type\": \"User\",                \"_links\": {                    \"self\": {                        \"href\": \"https: //openproject.org/api/v3/users/1\",                        \"title\": \"JohnSheppard-admin\"                    },                    \"workPackage\": {                        \"href\": \"https: //openproject.org/api/v3/work_packages/1\",                        \"title\": \"quisnumquamquivoluptatumquiapraesentiumblanditiisnisi\"                    }                },                \"id\": 1,                \"login\": \"admin\",                \"firstname\": \"John\",                \"lastname\": \"Sheppard\",                \"mail\": \"admin@example.net\",                \"type\": \"User\",                \"createdAt\": \"2014-05-21T08: 51: 20Z\",                \"updatedAt\": \"2014-05-22T09: 41: 29Z\"            }        ],        \"relations\": [            {                \"_type\": \"Relationship\",                \"_links\": {                    \"self\": {                        \"href\": \"https: //openproject.org/api/v3/relationships/1\",                        \"title\": \"WorkpackageAduplicatedbyWorkpackageB\"                    },                    \"workPackage\": {                        \"href\": \"https: //openproject.org/api/v3/work_packages/1\",                        \"title\": \"quisnumquamquivoluptatumquiapraesentiumblanditiisnisi\"                    },                    \"relatedWorkPackage\": {                        \"href\": \"https: //openproject.org/api/v3/work_packages/2\",                        \"title\": \"Loremipsum\"                    }                },                \"id\": 1,                \"type\": \"duplicates\",                \"relatedWorkPackageId\": 2,                \"relatedWorkPackageSubject\": \"Loremipsum\",                \"relatedWorkPackageType\": \"Bug\",                \"relatedWorkPackageStartDate\": \"2014-05-29\",                \"relatedWorkPackageDueDate\": \"2014-08-29\"            }        ],        \"attachments\": [            {                \"_type\": \"Attachment\",                \"_links\": {                    \"self\": {                        \"href\": \"https: //openproject.org/api/v3/attachments/1\",                        \"title\": \"Attachmentfilename\"                    },                    \"workPackage\": {                        \"href\": \"https: //openproject.org/api/v3/work_packages/1\",                        \"title\": \"quisnumquamquivoluptatumquiapraesentiumblanditiisnisi\"                    },                    \"author\": {                        \"href\": \"https: //openproject.org/api/v3/users/1\",                        \"title\": \"Userslogin\"                    }                },                \"id\": 1,                \"filename\": \"Attachmentfilename\",                \"filesize\": 30,                \"contentType\": \"txt\",                \"description\": \"Loremipsumdolorsitamet.\",                \"authorName\": \"JohnSheppard\",                \"authorLogin\": \"admin\",                \"authorMail\": \"admin@example.net\",                \"createdAt\": \"2014-05-21T08: 51: 20Z\"            }        ]    },    \"id\": 1,    \"subject\": \"quisnumquamquivoluptatumquiapraesentiumblanditiisnisi\",    \"type\": \"Support\",    \"description\": \"Cruxveleosdoloresadmoveosummaveritatisacerbitas.Deleovenustascubocurtusbalbussumoambitusvalens.Tenercotidieangelusillo.Citovertocomburo.Tergeovinculumsuccedoullussuppono.\",    \"status\": \"New\",    \"priority\": \"Normal\",    \"startDate\": \"2014-05-29\",    \"dueDate\": \"2014-08-29\",    \"estimatedTime\": {        \"units\": \"hours\",        \"value\": 10    },    \"percentageDone\": 0,    \"targetVersionId\": 1,    \"targetVersionName\": \"sprint-01\",    \"projectId\": 1,    \"projectName\": \"SeededProject\",    \"responsibleId\": 1,    \"responsibleName\": \"OpenProjectAdmin\",    \"responsibleLogin\": \"admin\",    \"responsibleMail\": \"admin@example.net\",    \"assigneeId\": 22,    \"assigneeName\": \"VivienneWindler\",    \"assigneeLogin\": \"Yoshiko8884\",    \"assigneeMail\": \"gabriel.osinski@glover.name\",    \"authorName\": \"DeliaSchneider\",    \"authorLogin\": \"Layla3137\",    \"authorMail\": \"charlene.terry@stromanko.org\",    \"createdAt\": \"2014-05-21T08: 51: 20Z\",    \"updatedAt\": \"2014-05-22T09: 41: 29Z\",    \"customProperties\": [        {            \"name\": \"Mycustomfield1\",            \"format\": \"text\",            \"value\": \"Loremipsum\"        }    ]}";
      return mockWorkPackageResponse;
    },

    configure: function() {
      // Configure Hyperagent to prefix every URL with the unicorn proxy.
      Hyperagent.configure('ajax', function ajax(options) {
        options.url = 'https://unicorn-cors-proxy.herokuapp.com/' + options.url;
        options.converters = {
          // Convert anything to text
          "* text": window.String,
          // Text to html (true = no transformation)
          "text html": true,
          // Evaluate text as a json expression
          "text json": HALAPIResource.parseApiaryResponse,
          // Parse text as xml
          "text xml": jQuery.parseXML
        }
        options.dataType = "json";

        return jQuery.ajax(options);
      });
    },

    setup: function(uri) {
      HALAPIResource.configure();
      return new Hyperagent.Resource({
        url: 'http://opapi.apiary-mock.com/' + uri,
        headers: {
          'X-Requested-With': 'Hyperagent'
        }
      });	
    }
  }

  return HALAPIResource;
});