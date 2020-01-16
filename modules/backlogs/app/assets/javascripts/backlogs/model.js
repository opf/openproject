//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

/***************************************
  MODEL
  Common methods for sprint, work_package,
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
      var self = this,
          baseClasses;

      baseClasses = 'ui-button ui-widget ui-state-default ui-corner-all';

      editor.dialog({
        buttons: [
        {
          text: 'OK',
          class: 'button -highlight',
          click: function () {
            self.copyFromDialog();
            $(this).dialog("close");
          }
        },
        {
          text: 'Cancel',
          class: 'button',
          click: function () {
            self.cancelEdit();
            $(this).dialog("close");
          }
        },
        ],
        close: function (e, ui) {
          if (e.which === 1 || e.which === 27) {
            self.cancelEdit();
          }
        },
        dialogClass: this.getType().toLowerCase() + '_editor_dialog',
        modal:       true,
        position:    { my: 'center', at: 'center', of: window },
        resizable:   false,
        title:       (this.isNew() ? this.newDialogTitle() : this.editDialogTitle())
      });
      editor.find(".editor").first().focus();
      $('.button').removeClass(baseClasses);
      $('.ui-icon-closethick').prop('title', 'close');
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
        var field, fieldType, fieldLabel, fieldName, fieldOrder, input, newInput,
            typeId, statusId ;

        field = $(this);
        fieldId = field.attr('field_id');
        fieldName = field.attr('fieldname');
        fieldLabel = field.attr('fieldlabel');
        fieldOrder = parseInt(field.attr('fieldorder'), 10);
        fieldType = field.attr('fieldtype') || 'input';

        if (!fieldLabel) {
          fieldLabel = fieldName.replace(/_/ig, " ").replace(/ id$/ig, "");
        }

        if (fieldType === 'select') {
          // Special handling for status_id => they are dependent of type_id
          if (fieldName === 'status_id') {
            typeId = $.trim(self.$.find('.type_id .v').html());
            // when creating stories we need to query the select directly
            if (typeId == '') {
                typeId = $('#type_id_options').val();
            }
            statusId = $.trim(self.$.find('.status_id .v').html());
            input = self.findFactory(typeId, statusId, fieldName);
          }
          else if (fieldName === 'type_id'){
            input = $('#' + fieldName + '_options').clone(true);
            // if the type changes the status dropdown has to be modified
            input.change(function(){
              typeId = $(this).val();
              statusId = $.trim(self.$.find('.status_id .v').html());
              newInput = self.findFactory(typeId, statusId, 'status_id');
              newInput = self.prepareInputFromFactory(newInput,fieldId,'status_id',fieldOrder,maxTabIndex);
              newInput = self.replaceStatusForNewType(input, newInput, $(this).parent().find('.status_id').val(), editor);
            });
          }
          else {
            input = $('#' + fieldName + '_options').clone(true);
          }
        }
        else {
          input = $(document.createElement(fieldType));
        }

        input  = self.prepareInputFromFactory(input, fieldId, fieldName, fieldOrder, maxTabIndex);

        // Copy the value in the field to the input element
        input.val(fieldType === 'select' ? field.children('.v').first().text() : field.text());


        // Add a date picker if field is a date field
        if (field.hasClass("date")) {
          input.datepicker({
            changeMonth: true,
            changeYear: true,
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

        $("<label />").attr({
          for: input.attr('id'),
        }).text(fieldLabel).appendTo(editor);
        input.appendTo(editor);
      });

      this.displayEditor(editor);
      this.editorDisplayed(editor);
      return editor;
    },

    findFactory: function (typeId, statusId, fieldName){
      // Find a factory
      newInput = $('#' + fieldName + '_options_' + typeId + '_' + statusId);
      if (newInput.length === 0) {
        // when no list found, only offer the default status
        // no list = combination is not valid / user has no rights -> workflow
        newInput = $('#status_id_options_default_' + statusId);
      }
      newInput = newInput.clone(true);
      return newInput;
    },

    prepareInputFromFactory: function (input,fieldId,fieldName,fieldOrder, maxTabIndex) {
      input.attr('id', fieldName + '_' + fieldId);
      input.attr('name', fieldName);
      input.attr('tabindex', fieldOrder + maxTabIndex);
      input.addClass(fieldName);
      input.addClass('editor');
      input.removeClass('template');
      input.removeClass('helper');
      return input;
    },

    replaceStatusForNewType: function (input,newInput, statusId, editor) {
      // Append an empty field and select it in case the old status is not available
      newInput.val(statusId); // try to set the status
      if (newInput.val() !== statusId){
          newInput.append(new Option('',''));
          newInput.val('');
      }
      newInput.focus(function () {
        self.$.data('focus', $(this).attr('name'));
      });

      newInput.blur(function () {
        self.$.data('focus', '');
      });
      // Find the old status dropdown and replace it with the new one
      input.parent().find('.status_id').replaceWith(newInput);
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

      if (!j.hasClass('editing') && !j.hasClass('dragging') && !j.hasClass('prevent_edit') && !$(e.target).hasClass('prevent_edit')) {
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
      this.$.addClass('error icon icon-bug');
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
      // Override as needed
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
          // if the user changes the type and that type does not offer the status
          // of the current story, the status field is set to blank
          // if the user saves this edit we will receive a validation error
          // the following 3 lines will prevent the override of the status id
          // otherwise we would loose the status id of the current ticket
          if (!(editor.val() === '' && fieldName === 'status_id')){
            j.children('div.' + fieldName).children('.v').text(editor.val());
          }

          j.children('div.' + fieldName).children('.t').text(editor.children(':selected').text());

        } else {
          j.children('div.' + fieldName).text(editor.val());
        }
      });

      // Mark the work_package as closed if so
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
      this.$.removeClass('error icon icon-bug');
    },

    unmarkSaving: function () {
      this.$.removeClass('saving');
    }
  });
}(jQuery));
