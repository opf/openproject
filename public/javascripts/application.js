function checkAll (id, checked) {
	var el = document.getElementById(id);
	for (var i = 0; i < el.elements.length; i++) {
    if (el.elements[i].disabled==false) {
      el.elements[i].checked = checked;
    }
	}
}

function addFileField() {
    var f = document.createElement("input");
    f.type = "file";
    f.name = "attachments[]";
    f.size = 30;
        
    p = document.getElementById("attachments_p");
    p.appendChild(document.createElement("br"));
    p.appendChild(f);
}