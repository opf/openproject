function submitForm(el) {
  submitFormWithConfirmation(el, true);
}

function submitFormWithConfirmation(el, withConfirmation) {
  if (!withConfirmation || confirm(I18n.t("js.text_are_you_sure"))) {
    jQuery(el).parent().submit();
  }

  return false;
}
