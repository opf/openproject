// ** I18N

// Calendar EN language
// Author: Mihai Bazon, <mihai_bazon@yahoo.com>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Diumenge",
 "Dilluns",
 "Dimarts",
 "Dimecres",
 "Dijous",
 "Divendres",
 "Dissabte",
 "Diumenge");

// Please note that the following array of short day names (and the same goes
// for short month names, _SMN) isn't absolutely necessary.  We give it here
// for exemplification on how one can customize the short day names, but if
// they are simply the first N letters of the full name you can simply say:
//
//   Calendar._SDN_len = N; // short day name length
//   Calendar._SMN_len = N; // short month name length
//
// If N = 3 then this is not needed either since we assume a value of 3 if not
// present, to be compatible with translation files that were written before
// this feature.

// short day names
Calendar._SDN = new Array
("dg",
 "dl",
 "dt",
 "dc",
 "dj",
 "dv",
 "ds",
 "dg");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Gener",
 "Febrer",
 "Març",
 "Abril",
 "Maig",
 "Juny",
 "Juliol",
 "Agost",
 "Setembre",
 "Octubre",
 "Novembre",
 "Desembre");

// short month names
Calendar._SMN = new Array
("Gen",
 "Feb",
 "Mar",
 "Abr",
 "Mai",
 "Jun",
 "Jul",
 "Ago",
 "Set",
 "Oct",
 "Nov",
 "Des");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Quant al calendari";

Calendar._TT["ABOUT"] =
"Selector DHTML de data/hora\n" +
"(c) dynarch.com 2002-2005 / Autor: Mihai Bazon\n" + // don't translate this this ;-)
"Per aconseguir l'última versió visiteu: http://www.dynarch.com/projects/calendar/\n" +
"Distribuït sota la llicència GNU LGPL. Vegeu http://gnu.org/licenses/lgpl.html per obtenir més detalls." +
"\n\n" +
"Selecció de la data:\n" +
"- Utilitzeu els botons \xab, \xbb per seleccionar l'any\n" +
"- Utilitzeu els botons " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " per seleccionar el mes\n" +
"- Mantingueu premut el botó del ratolí sobre qualsevol d'aquests botons per a una selecció més ràpida.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Selecció de l'hora:\n" +
"- Feu clic en qualsevol part de l'hora per incrementar-la\n" +
"- o premeu majúscules per disminuir-la\n" +
"- o feu clic i arrossegueu per a una selecció més ràpida.";

Calendar._TT["PREV_YEAR"] = "Any anterior (mantenir per menú)";
Calendar._TT["PREV_MONTH"] = "Mes anterior (mantenir per menú)";
Calendar._TT["GO_TODAY"] = "Anar a avui";
Calendar._TT["NEXT_MONTH"] = "Mes següent (mantenir per menú)";
Calendar._TT["NEXT_YEAR"] = "Any següent (mantenir per menú)";
Calendar._TT["SEL_DATE"] = "Sel·lecciona la data";
Calendar._TT["DRAG_TO_MOVE"] = "Arrossega per moure";
Calendar._TT["PART_TODAY"] = " (avui)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Primer mostra el %s";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Tanca";
Calendar._TT["TODAY"] = "Avui";
Calendar._TT["TIME_PART"] = "(Majúscules-)Feu clic o arrossegueu per canviar el valor";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d-%m-%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%A, %e de %B de %Y";

Calendar._TT["WK"] = "set";
Calendar._TT["TIME"] = "Hora:";
