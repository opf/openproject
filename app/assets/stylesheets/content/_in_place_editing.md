# In place editing

## In place editing: Multiple lines of text

### Read mode

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

### Edit mode

```

<div class="attributes-group ng-scope">
  <div class="attributes-group--header">
    <div class="attributes-group--header-container">
      <h3 class="attributes-group--header-text ng-binding">
        Description
      </h3>
    </div>
  </div>
  <div class="single-attribute wiki">
    <span>
      <div class="inplace-editor type-wiki_textarea attribute-description editable">
        <div class="ined-edit ng-scope" ng-if="isEditing">
          <form name="editForm">
            <div class="ined-input-wrapper">
              <div class="ined-input-wrapper-inner ng-scope" ng-include="" src="getTemplateUrl()">
                <div class="jstElements">
                  <button type="button" class="jstb_strong" title="Strong">
                    <span>Strong</span>
                  </button>
                  <button type="button" class="jstb_em" title="Italic">
                    <span>Italic</span>
                  </button>
                  <button type="button" class="jstb_ins" title="Underline">
                    <span>Underline</span>
                  </button>
                  <button type="button" class="jstb_del" title="Deleted">
                    <span>Deleted</span>
                  </button>
                  <button type="button" class="jstb_code" title="Inline Code">
                    <span>Inline Code</span>
                  </button>
                  <span id="space1" class="jstSpacer">&nbsp;</span>
                  <button type="button" class="jstb_h1" title="Heading 1">
                    <span>Heading 1</span>
                  </button>
                  <button type="button" class="jstb_h2" title="Heading 2">
                    <span>Heading 2</span></button>
                  <button type="button" class="jstb_h3" title="Heading 3">
                    <span>Heading 3</span>
                  </button>
                  <span id="space2" class="jstSpacer">&nbsp;</span>
                  <button type="button" class="jstb_ul" title="Unordered List">
                    <span>Unordered List</span>
                  </button>
                  <button type="button" class="jstb_ol" title="Ordered List">
                    <span>Ordered List</span>
                  </button>
                  <span id="space3" class="jstSpacer">&nbsp;</span>
                  <button type="button" class="jstb_bq" title="Quote">
                    <span>Quote</span>
                  </button>
                  <button type="button" class="jstb_unbq" title="Unquote">
                    <span>Unquote</span>
                  </button>
                  <button type="button" class="jstb_pre" title="Preformatted Text">
                    <span>Preformatted Text</span>
                  </button>
                  <span id="space4" class="jstSpacer">&nbsp;</span>
                  <button type="button" class="jstb_link" title="Link to a Wiki page">
                    <span>Link to a Wiki page</span>
                  </button>
                  <button type="button" class="jstb_img" title="Image">
                    <span>Image</span>
                  </button>
                  <div class="help">
                    <a href="/help/wiki_syntax" title="Text formatting" class="icon icon-help">
                      Text formatting
                    </a>
                  </div>
                  <button class="btn-preview" type="button">
                    Preview
                  </button>
                </div>
                <div class="jstEditor">
                  <textarea wiki-toolbar="" class="focus-input" name="value" title="Description: Edit" tabindex="0" rows="2">
                  </textarea>
                </div>
                <div class="jstHandle">
                </div>
              </div>
            </div>
             <div class="ined-dashboard">
               <div class="ined-errors"
                    role="alert"
                    ng-bind="error"
                    aria-live="polite"
                    aria-hidden="true">
               </div>
               <div class="ined-controls">
                 <accessible-by-keyboard class="ined-edit-save">
                   <a href="" tabindex="0">
                     <span>
                       <span class="icon-context icon-button icon-yes "
                             title="Description: Save"
                             icon-name="yes"
                             icon-title="Description: Save">
                         <span class="hidden-for-sighted ng-binding">
                           Description: Save
                         </span>
                       </span>
                     </span>
                   </a>
                 </accessible-by-keyboard>
                 <accessible-by-keyboard class="ined-edit-save-send">
                   <a href="" tabindex="0">
                     <span>
                       <span title="Description: Save and send email">
                         <i class="icon-yes"></i>
                         <i class="icon-mail"></i>
                       </span>
                     </span>
                   </a>
                 </accessible-by-keyboard>
                 <accessible-by-keyboard class="ined-edit-close">
                   <a href="" tabindex="0">
                     <span ng-transclude="">
                       <span class="icon-context icon-button icon-close "
                             title="Description: Cancel"
                             icon-name="close" icon-title="Description: Cancel">
                         <span class="hidden-for-sighted ng-binding">
                           Description: Cancel
                         </span>
                       </span>
                     </span>
                   </a>
                 </accessible-by-keyboard>
              </div>
            </div>
          </form>
        </div>
      </div>
    </span>
  </div>
</div>

```

## In place editing: Single line of text

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
