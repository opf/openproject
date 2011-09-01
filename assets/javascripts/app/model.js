/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

/***************************************
  MODEL
  Common methods for sprint, issue,
  story, task, and impediment
***************************************/

RB.Model = (function ($) {
  return RB.Object.create({

    initialize: function (el) {
      this.$ = $(el);
      this.el = el;
    },

    afterCreate: function (data, textStatus, xhr) {
      // Do nothing. Child objects may optionally override this
    },

    afterSave: function (data, textStatus, xhr) {
      var isNew, result;

      isNew = this.isNew();
      result = RB.Factory.initialize(RB.Model, data);

      this.unmarkSaving();
      this.refresh(result);

      if (isNew) {
        this.$.attr('id', result.$.attr('id'));
        this.afterCreate(data, textStatus, xhr);
      }
      else {
        this.afterUpdate(data, textStatus, xhr);
      }
    },

    afterUpdate: function (data, textStatus, xhr) {
      // Do nothing. Child objects may optionally override this
    },

    beforeSave: function () {
      // Do nothing. Child objects may or may not override this method
    },

    cancelEdit: function () {
      this.endEdit();
      if (this.isNew()) {
        this.$.hide('blind');
      }
    },

    close: function () {
      this.$.addClass('closed');
    },

    copyFromDialog: function () {
      var editors;

      if (this.$.find(".editors").length === 0) {
        editors = $("<div class='editors'></div>").appendTo(this.$);
      }
      else {
        editors = this.$.find(".editors").first();
      }
      editors.html("");
      editors.append($("#" + this.getType().toLowerCase() + "_editor").children(".editor"));
      this.saveEdits();
    },

    displayEditor: function (editor) {
      var pos = this.$.offset(),
          self = this;

      editor.dialog({
        buttons: {
          OK : function () {
            self.copyFromDialog();
            $(this).dialog("close");
          },
          Cancel : function () {
            self.cancelEdit();
            $(this).dialog("close");
          }
        },
        close: function (e, ui) {
          if (e.which === 27) {
            self.cancelEdit();
          }
        },
        dialogClass: this.getType().toLowerCase() + '_editor_dialog',
        modal:       true,
        position:    [pos.left - $(document).scrollLeft(), pos.top - $(document).scrollTop()],
        resizable:   false,
        title:       (this.isNew() ? this.newDialogTitle() : this.editDialogTitle())
      });
      editor.find(".editor").first().focus();
    },

    edit: function () {
      var editor = this.getEditor(),
          self = this,
          maxTabIndex = 0;

      $('.stories .editors .editor').each(function (index) {
        var value;

        value = parseInt($(this).attr('tabindex'), 10);

        if (maxTabIndex < value) {
          maxTabIndex = value;
        }
      });

      this.$.find('.editable').each(function (index) {
        var field, fieldType, fieldLabel, fieldName, fieldOrder, input,
            trackerId;

        field = $(this);
        fieldName = field.attr('fieldname');
        fieldLabel = field.attr('fieldlabel');
        fieldOrder = parseInt(field.attr('fieldorder'), 10);
        fieldType = field.attr('fieldtype') || 'input';

        if (!fieldLabel) {
          fieldLabel = fieldName.replace(/_/ig, " ").replace(/ id$/ig, "");
        }

        $("<label></label>").text(fieldLabel).appendTo(editor);

        if (fieldType === 'select') {
          // Special handling for status_id => they are dependent of tracker_id
          if (fieldName === 'status_id') {
            trackerId = $.trim(self.$.find('.tracker_id .v').html());
            trackerId = $('#' + fieldName + '_options_' + trackerId);

            if (trackerId.length !== 0) {
              input = trackerId.clone(true);
            }
            else {
              // now special list for this tracker id found - don't know why,
              // but better show all statuses than none.
              input = $('#' + fieldName + '_options').clone(true);
            }
          }
          else {
            input = $('#' + fieldName + '_options').clone(true);
          }
        }
        else {
          input = $(document.createElement(fieldType));
        }
        input.removeAttr('id');
        input.attr('name', fieldName);
        input.attr('tabindex', fieldOrder + maxTabIndex);
        input.addClass(fieldName);
        input.addClass('editor');
        input.removeClass('template');
        input.removeClass('helper');

        // Copy the value in the field to the input element
        input.val(fieldType === 'select' ? field.children('.v').first().text() : field.text());


        // Add a date picker if field is a date field
        if (field.hasClass("date")) {
          input.datepicker({
            changeMonth: true,
            changeYear: true,
            closeText: 'Close',
            dateFormat: 'yy-mm-dd',
            firstDay: 1,
            showOn: 'button',
            onClose: function () {
              $(this).focus();
            },
            selectOtherMonths: true,
            showAnim: '',
            showButtonPanel: true,
            showOtherMonths: true
          });

          // Remove click-bindings from div - since leaving the edit modus removes the input
          // and creates a new one
          // Open the datepicker when you click on the div (before in edit-mode)
          field.unbind("click");
          field.click(function(){input.datepicker("show");});

          // So that we won't need a datepicker button to re-show it
          input.mouseup(function () {
            $(this).datepicker("show");
          });
        }

        // Record in the model's root element which input field had the last focus. We will
        // use this information inside RB.Model.refresh() to determine where to return the
        // focus after the element has been refreshed with info from the server.
        input.focus(function () {
          self.$.data('focus', $(this).attr('name'));
        });

        input.blur(function () {
          self.$.data('focus', '');
        });

        input.appendTo(editor);
      });

      this.displayEditor(editor);
      this.editorDisplayed(editor);
      return editor;
    },

    // Override this method to change the dialog title
    editDialogTitle: function () {
      return "Edit " + this.getType();
    },

    editorDisplayed: function (editor) {
      // Do nothing. Child objects may override this.
    },

    endEdit: function () {
      this.$.removeClass('editing');
    },

    error: function (xhr, textStatus, error) {
      this.markError();
      RB.Dialog.msg($(xhr.responseText).find('.errors').html());
      this.processError(xhr, textStatus, error);
    },

    getEditor: function () {
      var editorId, editor;
      // Create the model editor if it does not yet exist
      editorId = this.getType().toLowerCase() + "_editor";

      editor = $("#" + editorId).html("");

      if (editor.length === 0) {
        editor = $("<div id='" + editorId + "'></div>").appendTo("body");
      }
      return editor;
    },

    getID: function () {
      return this.$.children('.id').children('.v').text();
    },

    getType: function () {
      throw "Child objects must override getType()";
    },

    handleClick: function (e) {
      var field, model, j, editor;

      field = $(this);
      model = field.parents('.model').first().data('this');
      j = model.$;

      if (!j.hasClass('editing') && !j.hasClass('dragging') && !$(e.target).hasClass('prevent_edit')) {
        editor = model.edit();
        editor.find('.' + $(e.currentTarget).attr('fieldname') + '.editor').focus();
      }
    },

    handleSelect: function (e) {
      var j = $(this),
          self = j.data('this');

      if (!$(e.target).hasClass('editable') &&
          !$(e.target).hasClass('checkbox') &&
          !j.hasClass('editing') &&
          e.target.tagName !== 'A' &&
          !j.hasClass('dragging')) {

        self.setSelection(!self.isSelected());
      }
    },

    isClosed: function () {
      return this.$.hasClass('closed');
    },

    isNew: function () {
      return this.getID() === "";
    },

    markError: function () {
      this.$.addClass('error');
    },

    markIfClosed: function () {
      throw "Child objects must override markIfClosed()";
    },

    markSaving: function () {
      this.$.addClass('saving');
    },

    // Override this method to change the dialog title
    newDialogTitle: function () {
      return "New " + this.getType();
    },

    open: function () {
      this.$.removeClass('closed');
    },

    processError: function (x, t, e) {
      // Do nothing. Feel free to override
    },

    refresh: function (obj) {
      this.$.html(obj.$.html());

      if (obj.$.length > 1) {
        // execute script tags, that were attached to the sources
        obj.$.filter('script').each(function () {
          try {
            $.globalEval($(this).html());
          }
          catch (e) {
          }
        });
      }

      if (obj.isClosed()) {
        this.close();
      } else {
        this.open();
      }
      this.refreshed();
    },

    refreshed: function () {
      // Override as needed
    },

    saveDirectives: function () {
      throw "Child object must implement saveDirectives()";
    },

    saveEdits: function () {
      var j = this.$,
          self = this,
          editors = j.find('.editor'),
          saveDir;

      // Copy the values from the fields to the proper html elements
      editors.each(function (index) {
        var editor, fieldName;

        editor = $(this);
        fieldName = editor.attr('name');
        if (this.type.match(/select/)) {
          j.children('div.' + fieldName).children('.v').text(editor.val());
          j.children('div.' + fieldName).children('.t').text(editor.children(':selected').text());
        // } else if (this.type.match(/textarea/)) {
        //   this.setValue('div.' + fieldName + ' .textile', editors[ii].value);
        //   this.setValue('div.' + fieldName + ' .html', '-- will be displayed after save --');
        } else {
          j.children('div.' + fieldName).text(editor.val());
        }
      });

      // Mark the issue as closed if so
      self.markIfClosed();

      // Get the save directives.
      saveDir = self.saveDirectives();

      self.beforeSave();

      self.unmarkError();
      self.markSaving();
      RB.ajax({
        type: "POST",
        url: saveDir.url,
        data: saveDir.data,
        success   : function (d, t, x) {
          self.afterSave(d, t, x);
        },
        error     : function (x, t, e) {
          self.error(x, t, e);
        }
      });
      self.endEdit();
    },

    unmarkError: function () {
      this.$.removeClass('error');
    },

    unmarkSaving: function () {
      this.$.removeClass('saving');
    }
  });
}(jQuery));
