# In place editing

# In place editing: Multiple lines of text

```
<div class="attributes-group">

  <div class="attributes-group--header">
    <div class="attributes-group--header-container">
      <h3 class="attributes-group--header-text">
        Description
      </h3>
    </div>
  </div>
  <div class="inplace-editor type-wiki_textarea attribute-description editable">
    <div class="ined-read-value editable">
      <span class="read-value-wrapper">
        <span>
          Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.

  Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.

  Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi.

  Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer
        </span>
      </span>
      <span class="editing-link-wrapper ng-scope">
        <accessible-by-keyboard execute="startediting()"
                                class="ng-isolate-scope">
          <a href="" tabindex="0">
            <span ng-transclude="">
              <span class="icon-context icon-button icon-edit "
                    title="description: edit"
                    icon-name="edit"
                    icon-title="description: edit">
                <span class="hidden-for-sighted">
                  description: edit
                </span>
              </span>
            </span>
          </a>
        </accessible-by-keyboard>
      </span>
    </div>
  </div>
</div>

```


# In place editing: Single line of text

```
<div class="attributes-group">
  <div class="attributes-group--header">
    <div class="attributes-group--header-container">
      <h3 class="attributes-group--header-text">
        Details
      </h3>
    </div>
  </div>
  <dl class="attributes-key-value">
    <dt class="attributes-key-value--key">
      Status
    </dt>
    <dd class="attributes-key-value--value-container">
      <div class="attributes-key-value--value -status">
        <div class="inplace-editor type-select2 attribute-status.name editable">
          <div class="ined-read-value editable" >
            <span class="read-value-wrapper">
              <span ng-bind="readValue">
                New
              </span>
            </span>
            <span ng-if="isEditable" class="editing-link-wrapper">
              <accessible-by-keyboard execute="startEditing()">
                <a href="" tabindex="0">
                  <span ng-transclude="">
                    <span class="icon-context icon-button icon-edit "
                          title="Status: Edit"
                          icon-name="edit"
                          icon-title="Status: Edit">
                      <span class="hidden-for-sighted">
                        Status: Edit
                      </span>
                    </span>
                  </span>
                </a>
              </accessible-by-keyboard>
            </span>
          </div>
        </div>
      </div>
    </dd>
  </dl>
</div>
```
