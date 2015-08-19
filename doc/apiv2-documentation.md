# OpenProject REST API v2 Documentation

__Be aware:__ The API v2 is marked as deprecated. Please read this [news article](https://www.openproject.org/news/65-api-v1-and-api-v2-deprecated-v3-in-development) for more information on that.

# General Information

## Authentication

The API supports both *basic auth* and authentication via an *API access key*. The latter is transmitted either as one of the parameters, named `key`, for a request or in the request header `X-OpenProject-API-Key`.
You can find a user's API key on their account page (/my/account).

Example request:

_GET_ `/api/v2/projects.xml?key=gh3g4h124grr871r8g`

## Formats

All actions support two formats:

* XML (`application/xml`)
* JSON (`application/json`)

The value in parenthesis is the `Content-Type` for the respective format to be transmitted when writing data (_POST_, _PUT_).
This header has to be transmitted even though the format is already indicated by the URL, e.g. when it ends with `.xml`.

## Terminology

What is referred to as _planning elements_ within the API (v2) is actually a _work package_ as far as the web interface is concerned. In previous versions the same thing may have been referred to as _issues_.

## Placeholders

In the rest of this document the string @:format@ will be used in URLs as a placeholder for an arbitrary format chosen from the available formats given above. I.e. you can substitute either `xml` or `json` for any occurrence of `:format`.

There is another placeholder called `:project_id`. This can either be substituted with a project's ID within the database or a project's _identifier_.
Furthermore the placeholder `:planning_element_id` has to be substituted with a planning element's ID within the database.

*Examples:*

The URL @/api/v2/projects/:project_id/edit@ can become:

* `/api/v2/projects/2/edit`
* `/api/v2/projects/maintenance/edit`

# API

__Be aware__ This section may be incomplete. Only _planning elements_ and _custom fields_ are described at the moment and even those sections may not be complete.

## Planning Elements

### Index (all)

_GET_ `/api/v2/projects/:project_id/planning_elements.:format`

Shows **all** _planning elements_ of a given _project_. For each _planning element_ a subset of the available information will be listed.

Example XML response excerpt:

```xml
<?xml version=""1.0"" encoding=""UTF-8""?>
<planning_elements type=""array"">
  <planning_element>
    <id type=""integer"">2</id>
    <subject>magni sint culpa</subject>
    <!-- ... -->
  </planning_element>
  <!-- more planning elements ... -->
</planning_elements>
```

### Index (filtered)

*TODO: Explain that _:project_id_ can in fact be a set of projects, identifiers or ids, that are comma-separated in the URL.*

Planning Elements can also be filtered using Query strings that correspond to work package filters. It is possible to filter on several conditions that are combined with logical AND. The following is an example filtering planning elements on `status_id`.

_GET_ `/api/v2/projects/:project_id/planning_elements.:format?f[]=status_id&op[status_id]=%3D&v[status_id][]=5`

The above query string corresponds to the following key-value pairs:

```
f[]            => status_id
op[status_id]  => =
v[status_id][] => 5
```

* The first key, `f[]`, defines a list of fields that are being filtered. In this example, we only filter for `status_id`.
* The `op[*]` keys define the operator for each field that is being filtered. The operator used here is the equal operator, which specifies that the `status_id` of the planning elements must be equal to one of the values provided.
* The `v[*][]` key defines the values on the right side of the operation. Here, the id 5 is provided, which results in the following combined statement:

The _status_id_ needs to _equal_ _5_.

The following constitutes a more complex query, combining two filters, one of which is an OR-combination of values:

_GET_
`/api/v2/projects/seeded_project,2/planning_elements.json?f[]=type_id&op[type_id]=%3D&v[type_id][]=3&f[]=status_id&op[status_id]=%3D&v[status_id][]=5&v[status_id][]=2`

The above query string corresponds to the following key-value pairs:

```
f[]            => type_id
op[type_id]    => =
v[type_id][]   => 3
f[]            => status_id
op[status_id]  => =
v[status_id][] => 5
v[status_id][] => 2
```

* The @f[]@ key is being set twice, which is being interpreted as an array of @[type_id, status_id]@ being assigned to @f[]@.
* The operatorts are subsequently set to the equal operator. Both @op[type_id]@ as well as @op[status_id]@ are set to @=@.
* The value field @v[type_id][]@ is set to 3. The value field @v[status_id][]@ is set twice, and like @f[]@, results in the array @[5, 2]@ being assigned as possible values. This results in the following combined statement:

The _type_id_ needs to _equal_ _3_ AND the _status_id_ needs to _equal_ either _5_ OR _2_.

The available operators can be found in the ""@Queries::Filter@"":https://github.com/opf/openproject/blob/dev/app/models/queries/filter.rb#L41-L74 class. Some of the available field options can be found in the ""@Queries::WorkPackages::AvailableFilterOptions@"":https://github.com/opf/openproject/blob/dev/app/models/queries/work_packages/available_filter_options.rb#L45-L56 class. The response when filtering planning elements is of the exact same structure than the unfiltered index action:

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<planning_elements type=""array"">
  <planning_element>
    <id type=""integer"">2</id>
    <subject>magni sint culpa</subject>
    <!-- ... -->
  </planning_element>
  <!-- more planning elements ... -->
</planning_elements>
```

There is a caveat when filtering trees of planning elements. When there are parent_ids in planning elements that correspond to planning elements that have been filtered out, i.e. the filter removes the parent of a planning element, then the parent_id of the planning elements is adjusted to the closest ancestor that is not filtered out. This could cause confusion when updating planning elements to the values that the server sent from a filtered query. The response to a filter can and occasionally will have objectively wrong parent_ids in favour of a reconstructable tree on the client side.

### Show

_GET_ @/api/v2/projects/:project_id/planning_elements/:planning_element_id.:format@

Shows a single planning element. The shown attributes include a list named @custom_fields@
which shows all _custom field values_ for that particular planning element.
Each _custom field value_ entry contains at least the name of the _custom field_ and its value for this _planning element_.

A possible response in XML could look like this:

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<work_package>
<planning_element>
  <id type=""integer"">723</id>
  <subject>aperiam est mollitia</subject>
  <description>Via venustas peccatus.</description>
  <project_id type=""integer"">1</project_id>
  <parent_id nil=""true""/>
  <status_id type=""integer"">3</status_id>
  <type_id type=""integer"">3</type_id>
  <start_date>2013-11-03</start_date>
  <due_date>2014-02-14</due_date>
  <created_at type=""datetime"">2013-10-18T09:35:48Z</created_at>
  <updated_at type=""datetime"">2013-10-18T09:35:48Z</updated_at>
  <destroyed type=""boolean"">true</destroyed>
  <custom_fields type=""array"">
    <custom_field>
      <value></value>
      <name>ad ut</name>
      <id type=""integer"">1</id>
    </custom_field>
    <custom_field>
      <value></value>
      <name>qui enim</name>
      <id type=""integer"">2</id>
    </custom_field>
    <custom_field>
      <value></value>
      <name>reiciendis qui</name>
      <id type=""integer"">3</id>
    </custom_field>
  </custom_fields>
  <project>
    <id type=""integer"">1</id>
    <identifier>seeded_project</identifier>
    <name>Seeded Project</name>
  </project>
  <type>
    <id type=""integer"">3</id>
    <name>Feature</name>
  </type>
  <status>
    <id type=""integer"">3</id>
    <name>Resolved</name>
  </status>
</planning_element>
```

### Update

_PUT_ @/api/v2/projects/:project_id/planning_elements/:planning_element_id.:format@

Updates a _planning element_. In addition to the usual attributes you can of course also update its _custom field values_. The request body for that in XML could look like this:

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<planning_element>
  <subject>Bug in front page</subject>
  <custom_fields type=""array"">
    <custom_field>
      <id>4</id>
      <value>pending</value>
    </custom_field>
  </custom_fields>
</planning_element>
```

Similarly when using JSON it would look like this:

```
{
    ""planning_element"": {
        ""custom_fields"": [
            {
                ""id"": 4,
                ""value"": ""pending""
            }
        ],
        ""subject"": ""Bug in front page""
    }
}
```

Those requests would set a _planning element's_ subject to ""Bug in front page"" and the value for the _custom field_ with the ID 4 to 'pending'.
A _custom field's_ ID can be found out by querying the available _custom fields_ as described in the _Custom Fields_ section.
You can find out about possible _planning element_ fields by querying a projects _planning elements_ which is described in the _Show_ section.

### Create

_POST_ @/api/v2/projects/:project_id/planning_elements.:format@

The request body is exactly the same as in the _Update_ operation.
Upon successful creation the response will be a redirect to the created _planning element_,
i.e. the URL to the new _planning element_ will be sent in the @Location@ header.

## Planning Element Journals

*This API endpoint is broken!* _Do not try to use it!_

## Planning Element Priorities

### Index

_GET_ @/api/v2/planning_element_priorities(.:format)

#### JSON

```
{
  ""planning_element_priorities"":[
                                  {
                                    ""id"":10,""name"":""Wichtig"", ""position"":1,""is_default"":false
                                  },
                                  {
                                    ""id"":11,""name"":""Normal"",""position"":2,""is_default"":true
                                  },
                                  {
                                    ""id"":13,""name"":""Niedrig"",""position"":3,""is_default"":false
                                  }
                                ]
}
```

#### XML

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<planning_element_priorities type=""array"">
  <planning_element_priority>
    <id type=""integer"">10</id>
    <name>Wichtig</name>
    <position type=""integer"">1</position>
    <is_default type=""boolean"">false</is_default>
  </planning_element_priority>
  <planning_element_priority>
    <id type=""integer"">11</id>
    <name>Normal</name>
    <position type=""integer"">2</position>
    <is_default type=""boolean"">true</is_default>
  </planning_element_priority>
  <planning_element_priority>
    <id type=""integer"">13</id>
    <name>Niedrig</name>
    <position type=""integer"">3</position>
    <is_default type=""boolean"">false</is_default>
  </planning_element_priority>
</planning_element_priorities>
```

## Custom Fields

This section describes all actions for _custom fields_ themselves, i.e. their definitions.

### Query Custom Fields

_GET_ @/api/v2/custom_fields.:format@

Returns the definitions for all custom fields visible to the user performing the query.
Example response:

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<custom_fields type=""array"">
  <custom_field>
    <id type=""integer"">7</id>
    <name>sausage</name>
    <field_format>list</field_format>
    <regexp></regexp>
    <min_length type=""integer"">0</min_length>
    <max_length type=""integer"">0</max_length>
    <is_required type=""boolean"">false</is_required>
    <is_filter type=""boolean"">false</is_filter>
    <searchable type=""boolean"">true</searchable>
    <is_for_all type=""boolean"">true</is_for_all>
    <position type=""integer"">7</position>
    <editable type=""boolean"">true</editable>
    <visible type=""boolean"">true</visible>
    <customized_type>planning_element</customized_type>
    <possible_values type=""array"">
      <possible_value>
        <value>Wiener</value>
      </possible_value>
      <possible_value>
        <value>Frankfurter</value>
      </possible_value>
      <possible_value>
        <value>Thüringer</value>
      </possible_value>
      <possible_value>
        <value>Berner</value>
      </possible_value>
      <possible_value>
        <value>Curry</value>
      </possible_value>
    </possible_values>
    <types type=""array"">
      <type>
        <id type=""integer"">1</id>
        <name>none</name>
      </type>
      <type>
        <id type=""integer"">2</id>
        <name>Bug</name>
      </type>
      <type>
        <id type=""integer"">3</id>
        <name>Feature</name>
      </type>
      <type>
        <id type=""integer"">4</id>
        <name>Support</name>
      </type>
      <type>
        <id type=""integer"">5</id>
        <name>Phase</name>
      </type>
      <type>
        <id type=""integer"">6</id>
        <name>Milestone</name>
      </type>
    </types>
    <projects type=""array""/>
  </custom_field>
  <custom_field>
    <id type=""integer"">8</id>
    <name>nonsense</name>
    <field_format>string</field_format>
    <regexp>.*</regexp>
    <min_length type=""integer"">0</min_length>
    <max_length type=""integer"">0</max_length>
    <is_required type=""boolean"">false</is_required>
    <is_filter type=""boolean"">false</is_filter>
    <searchable type=""boolean"">false</searchable>
    <is_for_all type=""boolean"">false</is_for_all>
    <position type=""integer"">1</position>
    <editable type=""boolean"">true</editable>
    <visible type=""boolean"">true</visible>
    <customized_type>project</customized_type>
  </custom_field>
</custom_fields>
```

### Query Planning Element Custom Fields

_GET_ @/api/v2/projects/:project_id/planning_element_custom_fields.:format@

Returns only the definitions of the custom fields which are enabled for a specific project.

## Planning Element Type Colors

### Index

_GET_ @/api/v2/colors.:format@

Shows all colors for the OpenProject instance. Returns the following structure:

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<colors type=""array"">
  <color>
    <id type=""integer"">1</id>
    <name>pjBlack</name>
    <position type=""integer"">1</position>
    <hexcode>#000000</hexcode>
    <created_at type=""datetime"">2013-11-20T10:00:58Z</created_at>
    <updated_at type=""datetime"">2013-11-20T10:00:58Z</updated_at>
  </color>
  <color>
    <id type=""integer"">2</id>
    <name>pjRed</name>
    <position type=""integer"">2</position>
    <hexcode>#FF0013</hexcode>
    <created_at type=""datetime"">2013-11-20T10:00:58Z</created_at>
    <updated_at type=""datetime"">2013-11-20T10:00:58Z</updated_at>
  </color>
  [...]
</colors>
```

The equivalent JSON:

```
{
    ""colors"": [
        {
            ""created_at"": ""2013-11-20T10:00:58Z"",
            ""hexcode"": ""#000000"",
            ""id"": 1,
            ""name"": ""pjBlack"",
            ""position"": 1,
            ""updated_at"": ""2013-11-20T10:00:58Z""
        },
        {
            ""created_at"": ""2013-11-20T10:00:58Z"",
            ""hexcode"": ""#FF0013"",
            ""id"": 2,
            ""name"": ""pjRed"",
            ""position"": 2,
            ""updated_at"": ""2013-11-20T10:00:58Z""
        }
    ]
}
```

### Show

_GET_ @/api/v2/colors/:color_id.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<color>
  <id type=""integer"">1</id>
  <name>pjBlack</name>
  <position type=""integer"">1</position>
  <hexcode>#000000</hexcode>
  <created_at type=""datetime"">2013-11-20T10:00:58Z</created_at>
  <updated_at type=""datetime"">2013-11-20T10:00:58Z</updated_at>
</color>
```

The corresponding JSON:

```
{
    ""color"": {
        ""created_at"": ""2013-11-20T10:00:58Z"",
        ""hexcode"": ""#000000"",
        ""id"": 1,
        ""name"": ""pjBlack"",
        ""position"": 1,
        ""updated_at"": ""2013-11-20T10:00:58Z""
    }
}
```

## Planning Element Types

### Index

_GET_ @/api/v2/planning_element_types.:format@

```

<?xml version=""1.0"" encoding=""UTF-8""?>
<planning_element_types type=""array"">
  <planning_element_type>
    <id type=""integer"">1</id>
    <name>none</name>
    <in_aggregation type=""boolean"">true</in_aggregation>
    <is_milestone type=""boolean"">false</is_milestone>
    <position type=""integer"">0</position>
    <is_default type=""boolean"">true</is_default>
    <color>
      <id type=""integer"">16</id>
      <name>pjSilver</name>
      <hexcode>#BFBFBF</hexcode>
    </color>
    <created_at>2013-11-20T10:00:59Z</created_at>
    <updated_at>2013-11-20T10:00:59Z</updated_at>
  </planning_element_type>
  <planning_element_type>
    <id type=""integer"">2</id>
    <name>Bug</name>
    <in_aggregation type=""boolean"">true</in_aggregation>
    <is_milestone type=""boolean"">false</is_milestone>
    <position type=""integer"">1</position>
    <is_default type=""boolean"">true</is_default>
    <color>
      <id type=""integer"">2</id>
      <name>pjRed</name>
      <hexcode>#FF0013</hexcode>
    </color>
    <created_at>2013-11-20T10:00:59Z</created_at>
    <updated_at>2013-11-20T10:00:59Z</updated_at>
  </planning_element_type>
  <planning_element_type>
    <id type=""integer"">3</id>
    <name>Feature</name>
    <in_aggregation type=""boolean"">true</in_aggregation>
    <is_milestone type=""boolean"">false</is_milestone>
    <position type=""integer"">2</position>
    <is_default type=""boolean"">true</is_default>
    <color>
      <id type=""integer"">4</id>
      <name>pjLime</name>
      <hexcode>#82FFA1</hexcode>
    </color>
    <created_at>2013-11-20T10:00:59Z</created_at>
    <updated_at>2013-11-20T10:00:59Z</updated_at>
  </planning_element_type>
  <planning_element_type>
    <id type=""integer"">4</id>
    <name>Support</name>
    <in_aggregation type=""boolean"">true</in_aggregation>
    <is_milestone type=""boolean"">false</is_milestone>
    <position type=""integer"">3</position>
    <is_default type=""boolean"">true</is_default>
    <color>
      <id type=""integer"">6</id>
      <name>pjBlue</name>
      <hexcode>#1E16F4</hexcode>
    </color>
    <created_at>2013-11-20T10:00:59Z</created_at>
    <updated_at>2013-11-20T10:00:59Z</updated_at>
  </planning_element_type>
  <planning_element_type>
    <id type=""integer"">5</id>
    <name>Phase</name>
    <in_aggregation type=""boolean"">true</in_aggregation>
    <is_milestone type=""boolean"">false</is_milestone>
    <position type=""integer"">4</position>
    <is_default type=""boolean"">true</is_default>
    <color>
      <id type=""integer"">16</id>
      <name>pjSilver</name>
      <hexcode>#BFBFBF</hexcode>
    </color>
    <created_at>2013-11-20T10:00:59Z</created_at>
    <updated_at>2013-11-20T10:00:59Z</updated_at>
  </planning_element_type>
  <planning_element_type>
    <id type=""integer"">6</id>
    <name>Milestone</name>
    <in_aggregation type=""boolean"">true</in_aggregation>
    <is_milestone type=""boolean"">true</is_milestone>
    <position type=""integer"">5</position>
    is_default type=""boolean"">true</is_default>
    <color>
      <id type=""integer"">13</id>
      <name>pjPurple</name>
      <hexcode>#86007B</hexcode>
    </color>
    <created_at>2013-11-20T10:00:59Z</created_at>
    <updated_at>2013-11-20T10:00:59Z</updated_at>
  </planning_element_type>
</planning_element_types>
```

The corresponding JSON:

```
{
    ""planning_element_types"": [
        {
            ""color"": {
                ""hexcode"": ""#BFBFBF"",
                ""id"": 16,
                ""name"": ""pjSilver""
            },
            ""created_at"": ""2013-11-20T10:00:59Z"",
            ""id"": 1,
            ""in_aggregation"": true,
            ""is_default"": true,
            ""is_milestone"": false,
            ""name"": ""none"",
            ""position"": 0,
            ""updated_at"": ""2013-11-20T10:00:59Z""
        },
        {
            ""color"": {
                ""hexcode"": ""#FF0013"",
                ""id"": 2,
                ""name"": ""pjRed""
            },
            ""created_at"": ""2013-11-20T10:00:59Z"",
            ""id"": 2,
            ""in_aggregation"": true,
            ""is_default"": true,
            ""is_milestone"": false,
            ""name"": ""Bug"",
            ""position"": 1,
            ""updated_at"": ""2013-11-20T10:00:59Z""
        },
        {
            ""color"": {
                ""hexcode"": ""#82FFA1"",
                ""id"": 4,
                ""name"": ""pjLime""
            },
            ""created_at"": ""2013-11-20T10:00:59Z"",
            ""id"": 3,
            ""in_aggregation"": true,
            ""is_default"": true,
            ""is_milestone"": false,
            ""name"": ""Feature"",
            ""position"": 2,
            ""updated_at"": ""2013-11-20T10:00:59Z""
        },
        {
            ""color"": {
                ""hexcode"": ""#1E16F4"",
                ""id"": 6,
                ""name"": ""pjBlue""
            },
            ""created_at"": ""2013-11-20T10:00:59Z"",
            ""id"": 4,
            ""in_aggregation"": true,
            ""is_default"": true,
            ""is_milestone"": false,
            ""name"": ""Support"",
            ""position"": 3,
            ""updated_at"": ""2013-11-20T10:00:59Z""
        },
        {
            ""color"": {
                ""hexcode"": ""#BFBFBF"",
                ""id"": 16,
                ""name"": ""pjSilver""
            },
            ""created_at"": ""2013-11-20T10:00:59Z"",
            ""id"": 5,
            ""in_aggregation"": true,
            ""is_default"": true,
            ""is_milestone"": false,
            ""name"": ""Phase"",
            ""position"": 4,
            ""updated_at"": ""2013-11-20T10:00:59Z""
        },
        {
            ""color"": {
                ""hexcode"": ""#86007B"",
                ""id"": 13,
                ""name"": ""pjPurple""
            },
            ""created_at"": ""2013-11-20T10:00:59Z"",
            ""id"": 6,
            ""in_aggregation"": true,
            ""is_default"": true,
            ""is_milestone"": true,
            ""name"": ""Milestone"",
            ""position"": 5,
            ""updated_at"": ""2013-11-20T10:00:59Z""
        }
    ]
}
```

### Show

_GET_ @/api/v2/planning_element_types/:planning_element_type_id.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<planning_element_type>
  <id type=""integer"">1</id>
  <name>none</name>
  <in_aggregation type=""boolean"">true</in_aggregation>
  <is_milestone type=""boolean"">false</is_milestone>
  <position type=""integer"">0</position>
  <is_default type=""boolean"">true</is_default>
  <color>
    <id type=""integer"">16</id>
    <name>pjSilver</name>
    <hexcode>#BFBFBF</hexcode>
  </color>
  <created_at>2013-11-20T10:00:59Z</created_at>
  <updated_at>2013-11-20T10:00:59Z</updated_at>
</planning_element_type>
```

The corresponding JSON:

```
{
    ""planning_element_type"": {
        ""color"": {
            ""hexcode"": ""#BFBFBF"",
            ""id"": 16,
            ""name"": ""pjSilver""
        },
        ""created_at"": ""2013-11-20T10:00:59Z"",
        ""id"": 1,
        ""in_aggregation"": true,
        ""is_default"": true,
        ""is_milestone"": false,
        ""name"": ""none"",
        ""position"": 0,
        ""updated_at"": ""2013-11-20T10:00:59Z""
    }
}
```

## Project Types

### Index

_GET_ @/api/v2/project_types.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<project_types type=""array"">
  <project_type>
    <id type=""integer"">1</id>
    <name>Test</name>
    <allows_association type=""boolean"">true</allows_association>
    <position type=""integer"">1</position>
    <created_at type=""datetime"">2013-12-18T10:12:23Z</created_at>
    <updated_at type=""datetime"">2013-12-18T10:12:23Z</updated_at>
  </project_type>
  <project_type>
    <id type=""integer"">2</id>
    <name>Default</name>
    <allows_association type=""boolean"">true</allows_association>
    <position type=""integer"">2</position>
    <created_at type=""datetime"">2013-12-18T10:12:40Z</created_at>
    <updated_at type=""datetime"">2013-12-18T10:12:40Z</updated_at>
  </project_type>
</project_types>
```

The corresponding JSON:

```
{
    ""project_types"": [
        {
            ""allows_association"": true,
            ""created_at"": ""2013-12-18T10:12:23Z"",
            ""id"": 1,
            ""name"": ""Test"",
            ""position"": 1,
            ""updated_at"": ""2013-12-18T10:12:23Z""
        },
        {
            ""allows_association"": true,
            ""created_at"": ""2013-12-18T10:12:40Z"",
            ""id"": 2,
            ""name"": ""Default"",
            ""position"": 2,
            ""updated_at"": ""2013-12-18T10:12:40Z""
        }
    ]
}
```

### Show

_GET_ @/api/v2/project_types/:project_type_id.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<project_type>
  <id type=""integer"">1</id>
  <name>Test</name>
  <allows_association type=""boolean"">true</allows_association>
  <position type=""integer"">1</position>
  <created_at type=""datetime"">2013-12-18T10:12:23Z</created_at>
  <updated_at type=""datetime"">2013-12-18T10:12:23Z</updated_at>
</project_type>
```

The corresponding JSON:

```
{
    ""project_type"": {
        ""allows_association"": true,
        ""created_at"": ""2013-12-18T10:12:23Z"",
        ""id"": 1,
        ""name"": ""Test"",
        ""position"": 1,
        ""updated_at"": ""2013-12-18T10:12:23Z""
    }
}
```

## Projects

### Index (all)

_GET_ @/api/v2/projects.:format@

Shows all projects for the OpenProject instance. Returns the following structure:


```
<?xml version=""1.0"" encoding=""UTF-8""?>
<projects type=""array"">
  <project>
    <id type=""integer"">1</id>
    <name>Seeded Project</name>
    <identifier>seeded_project</identifier>
    <description>
      Aut facilis sit officia quasi autem temporibus aut. Id culpa debitis non recusandae quibusdam dolor. Esse et et quaerat hic sapiente et. Voluptatem iste cupiditate consequatur eius laborum. Velit aspernatur provident est corrupti est. Consectetur error veritatis reprehenderit voluptas sint.
    </description>
    <project_type_id nil=""true""/>
    <parent_id nil=""true""/>
    <responsible_id nil=""true""/>
    <type_ids type=""array"">
      <type_id type=""integer"">1</type_id>
      <type_id type=""integer"">2</type_id>
      <type_id type=""integer"">3</type_id>
      <type_id type=""integer"">4</type_id>
      <type_id type=""integer"">5</type_id>
      <type_id type=""integer"">6</type_id>
    </type_ids>
    <created_on>2013-11-20T10:01:01Z</created_on>
    <updated_on>2013-11-20T10:01:01Z</updated_on>
  </project>
  <project>
    <id type=""integer"">2</id>
    <name>Test</name>
    <identifier>test</identifier>
    <description/>
    <project_type_id nil=""true""/>
    <parent_id nil=""true""/>
    <responsible_id type=""integer"">1</responsible_id>
    <type_ids type=""array"">
      <type_id type=""integer"">1</type_id>
      <type_id type=""integer"">2</type_id>
      <type_id type=""integer"">3</type_id>
      <type_id type=""integer"">4</type_id>
      <type_id type=""integer"">5</type_id>
      <type_id type=""integer"">6</type_id>
    </type_ids>
    <created_on>2013-11-20T13:51:42Z</created_on>
    <updated_on>2013-12-17T08:59:52Z</updated_on>
  </project>
</projects>
```

The equivalent JSON:

```
{
    ""projects"": [
        {
            ""created_on"": ""2013-11-20T10:01:01Z"",
            ""description"": ""Aut facilis sit officia quasi autem temporibus aut. Id culpa debitis non recusandae quibusdam dolor. Esse et et quaerat hic sapiente et. Voluptatem iste cupiditate consequatur eius laborum. Velit aspernatur provident est corrupti est. Consectetur error veritatis reprehenderit voluptas sint."",
            ""id"": 1,
            ""identifier"": ""seeded_project"",
            ""name"": ""Seeded Project"",
            ""parent_id"": null,
            ""project_type_id"": null,
            ""responsible_id"": null,
            ""type_ids"": [
                1,
                2,
                3,
                4,
                5,
                6
            ],
            ""updated_on"": ""2013-11-20T10:01:01Z""
        },
        {
            ""created_on"": ""2013-11-20T13:51:42Z"",
            ""description"": """",
            ""id"": 2,
            ""identifier"": ""test"",
            ""name"": ""Test"",
            ""parent_id"": null,
            ""project_type_id"": null,
            ""responsible_id"": 1,
            ""type_ids"": [
                1,
                2,
                3,
                4,
                5,
                6
            ],
            ""updated_on"": ""2013-12-17T08:59:52Z""
        }
    ]
}
```

### Index (some)


It is possible to retrieve only a set of projects, however not dynamically filtered. To retrieve only a set of projects from the index action, it is possible to query with a list of comma-separated ids or identifiers.

```
http://localhost:3000/api/v2/projects.json?ids=seeded_project,2
```

_GET_ @/api/v2/projects.:format?ids=:project_id@

Ids and identifiers can be interchanged, providing identification for a project multiple times will not trigger multiple occurances of that project in the response.
Providing only one id in the field of ids will result in only one project being returned, which is still different from the show action.

### Show

_GET_ @/api/v2/projects/:project_id.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<project>
  <id type=""integer"">2</id>
  <name>Test</name>
  <identifier>test</identifier>
  <description></description>
  <project_type_id nil=""true""/>
  <permissions>
    <view_planning_elements type=""boolean"">true</view_planning_elements>
    <edit_planning_elements type=""boolean"">true</edit_planning_elements>
    <delete_planning_elements type=""boolean"">true</delete_planning_elements>
  </permissions>
  <responsible>
    <id type=""integer"">1</id>
    <name>OpenProject Admin</name>
  </responsible>
  <created_on>2013-11-20T13:51:42Z</created_on>
  <updated_on>2013-12-17T08:59:52Z</updated_on>
  <types type=""array"">
    <type>
      <id type=""integer"">1</id>
      <name>none</name>
      <is_milestone type=""boolean"">false</is_milestone>
      <color>
        <id type=""integer"">16</id>
        <name>pjSilver</name>
        <hexcode>#BFBFBF</hexcode>
      </color>
    </type>
    <type>
      <id type=""integer"">2</id>
      <name>Bug</name>
      <is_milestone type=""boolean"">false</is_milestone>
      <color>
        <id type=""integer"">2</id>
        <name>pjRed</name>
        <hexcode>#FF0013</hexcode>
      </color>
    </type>
    <type>
      <id type=""integer"">3</id>
      <name>Feature</name>
      <is_milestone type=""boolean"">false</is_milestone>
      <color>
        <id type=""integer"">4</id>
        <name>pjLime</name>
        <hexcode>#82FFA1</hexcode>
      </color>
    </type>
    <type>
      <id type=""integer"">4</id>
      <name>Support</name>
      <is_milestone type=""boolean"">false</is_milestone>
      <color>
        <id type=""integer"">6</id>
        <name>pjBlue</name>
        <hexcode>#1E16F4</hexcode>
      </color>
    </type>
    <type>
      <id type=""integer"">5</id>
      <name>Phase</name>
      <is_milestone type=""boolean"">false</is_milestone>
      <color>
        <id type=""integer"">16</id>
        <name>pjSilver</name>
        <hexcode>#BFBFBF</hexcode>
      </color>
    </type>
    <type>
      <id type=""integer"">6</id>
      <name>Milestone</name>
      <is_milestone type=""boolean"">true</is_milestone>
      <color>
        <id type=""integer"">13</id>
        <name>pjPurple</name>
        <hexcode>#86007B</hexcode>
      </color>
    </type>
  </types>
  <custom_fields type=""array""/>
</project>
```

The corresponding JSON:

```
{
    ""project"": {
        ""created_on"": ""2013-11-20T13:51:42Z"",
        ""custom_fields"": [],
        ""description"": """",
        ""id"": 2,
        ""identifier"": ""test"",
        ""name"": ""Test"",
        ""permissions"": {
            ""delete_planning_elements"": true,
            ""edit_planning_elements"": true,
            ""view_planning_elements"": true
        },
        ""project_type_id"": null,
        ""responsible"": {
            ""id"": 1,
            ""name"": ""OpenProject Admin""
        },
        ""types"": [
            {
                ""color"": {
                    ""hexcode"": ""#BFBFBF"",
                    ""id"": 16,
                    ""name"": ""pjSilver""
                },
                ""id"": 1,
                ""is_milestone"": false,
                ""name"": ""none""
            },
            {
                ""color"": {
                    ""hexcode"": ""#FF0013"",
                    ""id"": 2,
                    ""name"": ""pjRed""
                },
                ""id"": 2,
                ""is_milestone"": false,
                ""name"": ""Bug""
            },
            {
                ""color"": {
                    ""hexcode"": ""#82FFA1"",
                    ""id"": 4,
                    ""name"": ""pjLime""
                },
                ""id"": 3,
                ""is_milestone"": false,
                ""name"": ""Feature""
            },
            {
                ""color"": {
                    ""hexcode"": ""#1E16F4"",
                    ""id"": 6,
                    ""name"": ""pjBlue""
                },
                ""id"": 4,
                ""is_milestone"": false,
                ""name"": ""Support""
            },
            {
                ""color"": {
                    ""hexcode"": ""#BFBFBF"",
                    ""id"": 16,
                    ""name"": ""pjSilver""
                },
                ""id"": 5,
                ""is_milestone"": false,
                ""name"": ""Phase""
            },
            {
                ""color"": {
                    ""hexcode"": ""#86007B"",
                    ""id"": 13,
                    ""name"": ""pjPurple""
                },
                ""id"": 6,
                ""is_milestone"": true,
                ""name"": ""Milestone""
            }
        ],
        ""updated_on"": ""2013-12-17T08:59:52Z""
    }
}
```

## Reportings

When calling the index action it is possible to scope the reportings that ought to be retrieved to @via_target@, @via_source@, or not at all.
* *@via_target@* will only regard reportings that _report into the project that the reportings are retrieved from_.
* *@via_source@* will only regard reportings that _the project that the reportings are retrieved from reports into_.
* *No scoping* will result in all reportings being regarded that _the project the reportings are retrieved from is involved in_.

### Index (all)

_GET_ @/api/v2/projects/:project_id/reportings.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<reportings type=""array"">
  <reporting>
    <id type=""integer"">1</id>
    <reported_project_status>
      <id type=""integer"">13</id>
      <name>Green</name>
    </reported_project_status>
    <reported_project_status_comment></reported_project_status_comment>
    <created_at>2013-11-21T13:10:56Z</created_at>
    <updated_at>2013-12-18T10:22:20Z</updated_at>
    <reporting_to_project>
      <id type=""integer"">1</id>
      <identifier>seeded_project</identifier>
      <name>Seeded Project</name>
    </reporting_to_project>
    <project>
      <id type=""integer"">2</id>
      <identifier>test</identifier>
      <name>Test</name>
    </project>
  </reporting>
</reportings>
```

The corresponding JSON:

```
{
    ""reportings"": [
        {
            ""created_at"": ""2013-11-21T13:10:56Z"",
            ""id"": 1,
            ""project"": {
                ""id"": 2,
                ""identifier"": ""test"",
                ""name"": ""Test""
            },
            ""reported_project_status"": {
                ""id"": 13,
                ""name"": ""Green""
            },
            ""reported_project_status_comment"": """",
            ""reporting_to_project"": {
                ""id"": 1,
                ""identifier"": ""seeded_project"",
                ""name"": ""Seeded Project""
            },
            ""updated_at"": ""2013-12-18T10:22:20Z""
        }
    ]
}
```

### Index (filtered)

Reportings can also be filtered based on the projects involved. One of the involved projects needs to conform to the specified query parameters. Reportings filters support:

* Project types via the @project_types@ field.
* Project status via the @project_statuses@ field.
* Responsible via the @project_responsibles@ field.

_GET_ @/api/v2/projects/:project_id/reportings.:format?only=via_target&project_types=2&project_statuses=13&project_responsibles=-1,1@

The above query string corresponds to the following key-value pairs:

```
only                 => via_target
project_types        => 2
project_statuses     => 13
project_responsibles => -1,1
```

The values can be comma-separated lists of ids. A _-1_ value in the list stands for the _(none)_ value, i.e. the field is allowed not to be set (nil). It is also possible to filter for timelines first level grouping criteria as well as project parents in general. The relevant filters can be found in ""Api::V2::ReportingsController"":https://github.com/opf/openproject/blob/dev/app/controllers/api/v2/reportings_controller.rb#L95-L165.

## Project Associations

*This API endpoint is deprecated!* _Don't use it!_

### Available Project

_GET_ @/api/v2/projects/:project_id/project_associations/available_projects.:format@

### Index

_GET_ @/api/v2/projects/:project_id/project_associations/.:format@

### Create

_POST_ @/api/v2/projects/:project_id/project_associations/.:format@

### New

_GET_ @/api/v2/projects/:project_id/project_associations/new.:format@

### Edit

_GET_ @/api/v2/projects/:project_id/project_associations/:id/edit.:format@

### Show

_GET_ @/api/v2/projects/:project_id/project_associations/:id.:format@

### Update

_PUT_ @/api/v2/projects/:project_id/project_associations/:id.:format@

### Destroy

_POST_ @/api/v2/projects/:project_id/project_associations/:id.:format@

## Statuses

### Index

_GET_ @/api/v2/statuses.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<statuses type=""array"">
  <status>
    <id type=""integer"">1</id>
    <name>New</name>
    <position type=""integer"">1</position>
    <is_default type=""boolean"">true</is_default>
    <is_closed type=""boolean"">false</is_closed>
    <default_done_ratio nil=""true""/>
  </status>
  <status>
    <id type=""integer"">3</id>
    <name>Resolved</name>
    <position type=""integer"">3</position>
    <is_default type=""boolean"">false</is_default>
    <is_closed type=""boolean"">false</is_closed>
    <default_done_ratio nil=""true""/>
  </status>
  <status>
    <id type=""integer"">4</id>
    <name>Feedback</name>
    <position type=""integer"">4</position>
    <is_default type=""boolean"">false</is_default>
    <is_closed type=""boolean"">false</is_closed>
    <default_done_ratio nil=""true""/>
  </status>
  <status>
    <id type=""integer"">5</id>
    <name>Closed</name>
    <position type=""integer"">5</position>
    <is_default type=""boolean"">false</is_default>
    <is_closed type=""boolean"">true</is_closed>
    <default_done_ratio nil=""true""/>
  </status>
  <status>
    <id type=""integer"">2</id>
    <name>In Progress</name>
    <position type=""integer"">7</position>
    <is_default type=""boolean"">false</is_default>
    <is_closed type=""boolean"">false</is_closed>
    <default_done_ratio nil=""true""/>
  </status>
  <status>
    <id type=""integer"">6</id>
    <name>Rejected</name>
    <position type=""integer"">6</position>
    <is_default type=""boolean"">false</is_default>
    <is_closed type=""boolean"">true</is_closed>
    <default_done_ratio nil=""true""/>
  </status>
</statuses>
```

The corresponding JSON:

```
{
    ""statuses"": [
        {
            ""default_done_ratio"": null,
            ""id"": 1,
            ""is_closed"": false,
            ""is_default"": true,
            ""name"": ""New"",
            ""position"": 1
        },
        {
            ""default_done_ratio"": null,
            ""id"": 3,
            ""is_closed"": false,
            ""is_default"": false,
            ""name"": ""Resolved"",
            ""position"": 3
        },
        {
            ""default_done_ratio"": null,
            ""id"": 4,
            ""is_closed"": false,
            ""is_default"": false,
            ""name"": ""Feedback"",
            ""position"": 4
        },
        {
            ""default_done_ratio"": null,
            ""id"": 5,
            ""is_closed"": true,
            ""is_default"": false,
            ""name"": ""Closed"",
            ""position"": 5
        },
        {
            ""default_done_ratio"": null,
            ""id"": 2,
            ""is_closed"": false,
            ""is_default"": false,
            ""name"": ""In Progress"",
            ""position"": 7
        },
        {
            ""default_done_ratio"": null,
            ""id"": 6,
            ""is_closed"": true,
            ""is_default"": false,
            ""name"": ""Rejected"",
            ""position"": 6
        }
    ]
}
```

### Show

_GET_ @/api/v2/statuses/:status_id.:format@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<status>
  <id type=""integer"">1</id>
  <name>New</name>
  <position type=""integer"">1</position>
  <is_default type=""boolean"">true</is_default>
  <is_closed type=""boolean"">false</is_closed>
  <default_done_ratio nil=""true""/>
</status>
```

The corresponding JSON:

```
{
    ""status"": {
        ""default_done_ratio"": null,
        ""id"": 1,
        ""is_closed"": false,
        ""is_default"": true,
        ""name"": ""New"",
        ""position"": 1
    }
}
```

## Users

### Index (some)

Users can not be indexed w/o specific ids. To retrieve some users, their ids must be provided in the query string as a comma seperated list.

It is possible that users that exist will not be returned when their id is provided. Only users that stisfy the visibility condition will be returned, all other users will be omitted in the result. The visible condition is defined in the ""@Principal@"":https://github.com/opf/openproject/blob/dev/app/models/principal.rb#L87-L95 class.

_GET_ @/api/v2/users.:format?ids=:user_ids@

```
<?xml version=""1.0"" encoding=""UTF-8""?>
<users type=""array"">
  <user>
    <id type=""integer"">1</id>
    <firstname>OpenProject</firstname>
    <lastname>Admin</lastname>
    <name>OpenProject Admin</name>
  </user>
</users>
```

The corresponding JSON:

```
{
    ""users"": [
        {
            ""firstname"": ""OpenProject"",
            ""id"": 1,
            ""lastname"": ""Admin"",
            ""name"": ""OpenProject Admin""
        }
    ]
}
```

## Workflows

### Index

* Related Tickets
** #3113

A list of workflows is a list of ""<code>type</code>"":https://www.openproject.org/projects/openproject/wiki/API_v2/#14-Planning-Element-Types / ""<code>status</code>"":https://www.openproject.org/projects/openproject/wiki/API_v2/#18-Statuses pairs and their respective transitions. Transitions are ""<code>status</code>"":https://www.openproject.org/projects/openproject/wiki/API_v2/#18-Statuses / <code>scope</code> pairs.

A <code>scope</code> can have one of three values <code>role</code>|<code>author</code>|<code>assignee</code>. Thus, if atransition has the scope <code>author</code>, only a user who is author of the respective ticket may be allowed to use this transition. The same is valid for <code>assignee</code>. The scope <code>role</code> is valid in the cases where the user is neither author or assignee.

_GET_ @/api/v2/projects/:project_id/workflows(.:format)@

#### JSON

```
{""workflows"":
  [
   {""type_id"":1,
   ""old_status_id"":2,
   ""transitions"":[
                  {""new_status_id"":3,""scope"":""author""},
                  {""new_status_id"":14,""scope"":""role""},
                  {""new_status_id"":13,""scope"":""role""}
                 ]}
  ]}
```

#### XML

```
<workflows type=""array"">
  <workflow>
    <type_id type=""integer"">1</type_id>
    <old_status_id type=""integer"">2</old_status_id>
    <transitions type=""array"">
      <transition>
        <new_status_id type=""integer"">3</new_status_id>
        <scope type=""symbol"">author</scope>
      </transition>
      <transition>
        <new_status_id type=""integer"">14</new_status_id>
        <scope type=""symbol"">role</scope>
      </transition>
      <transition>
        <new_status_id type=""integer"">13</new_status_id>
        <scope type=""symbol"">role</scope>
      </transition>
  </transitions>
</workflows>
```

## Authentication

### Index

* Related Tickets
** #4163

This end-point returns the following HTTP status codes:

| *HTTP Status Code* | *Meaning* | *Response*                                           |
| ------------------ | --------- | ---------------------------------------------------- |
| 200                | Success   | Authentication Data                                  |
| 401                | Unauthorized - cannot find user for given credentials    | empty |
| 403                | Forbidden - API does not allow authentication (Settings) | empty |

If the authentication is successful, the API returns data that contains the OpenProject user id for the authenticated user.

_GET_ @/api/v2/authentication(.:format)@

#### JSON

```
{
 ""authorization"":
 {
  ""authorized"":true,
  ""authenticated_user_id"":96
 }
}
```

#### XML

```
<authorization>
  <authorized type=""boolean"">true</authorized>
  <authenticated_user_id type=""integer"">96</authenticated_user_id>
</authorization>
```


# Examples

Here are few example requests made using _curl_ are shown:

## Creating a Planning Element (w/ authentication)

Request:

```bash
curl -u admin:admin -X POST --header ""Content-Type: application/json"" -d '{""planning_element"": {""subject"": ""Test Issue"", ""status_id"": 1 /* new */, ""type_id"": 3 /* Feature */}' http://localhost:3000/api/v2/projects/seeded_project/planning_elements.json
```

Response:

```html
<html>
  <body>
    You are being <a href=""http://localhost:3000/api/v2/projects/seeded_project/planning_elements/732.xml"">redirected</a>.
  </body>
</html>
``

