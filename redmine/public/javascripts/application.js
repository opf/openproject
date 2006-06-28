function checkAll (id, checked) {
	var el = document.getElementById(id);
	for (var i = 0; i < el.elements.length; i++) {
    if (el.elements[i].disabled==false) {
      el.elements[i].checked = checked;
    }
	}
}