// ** I18N

// Calendar GL (galician) language
// Author: Martín Vázquez Cabanas, <eu@martinvazquez.net>
// Updated: 2009-01-23
// Encoding: utf-8
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Domingo",
 "Luns",
 "Martes",
 "Mércores",
 "Xoves",
 "Venres",
 "Sábado",
 "Domingo");

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
("Dom",
 "Lun",
 "Mar",
 "Mér",
 "Xov",
 "Ven",
 "Sáb",
 "Dom");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Xaneiro",
 "Febreiro",
 "Marzo",
 "Abril",
 "Maio",
 "Xuño",
 "Xullo",
 "Agosto",
 "Setembro",
 "Outubro",
 "Novembro",
 "Decembro");

// short month names
Calendar._SMN = new Array
("Xan",
 "Feb",
 "Mar",
 "Abr",
 "Mai",
 "Xun",
 "Xull",
 "Ago",
 "Set",
 "Out",
 "Nov",
 "Dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Acerca do calendario";

Calendar._TT["ABOUT"] =
"Selector DHTML de Data/Hora\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"Para conseguila última versión visite: http://www.dynarch.com/projects/calendar/\n" +
"Distribuído baixo licenza GNU LGPL. Visite http://gnu.org/licenses/lgpl.html para máis detalles." +
"\n\n" +
"Selección de data:\n" +
"- Use os botóns \xab, \xbb para seleccionalo ano\n" +
"- Use os botóns " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " para seleccionalo mes\n" +
"- Manteña pulsado o rato en calquera destes botóns para unha selección rápida.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Selección de hora:\n" +
"- Pulse en calquera das partes da hora para incrementala\n" +
"- ou pulse maiúsculas mentres fai clic para decrementala\n" +
"- ou faga clic e arrastre o rato para unha selección máis rápida.";

Calendar._TT["PREV_YEAR"] = "Ano anterior (manter para menú)";
Calendar._TT["PREV_MONTH"] = "Mes anterior (manter para menú)";
Calendar._TT["GO_TODAY"] = "Ir a hoxe";
Calendar._TT["NEXT_MONTH"] = "Mes seguinte (manter para menú)";
Calendar._TT["NEXT_YEAR"] = "Ano seguinte (manter para menú)";
Calendar._TT["SEL_DATE"] = "Seleccionar data";
Calendar._TT["DRAG_TO_MOVE"] = "Arrastrar para mover";
Calendar._TT["PART_TODAY"] = " (hoxe)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Facer %s primeiro día da semana";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Pechar";
Calendar._TT["TODAY"] = "Hoxe";
Calendar._TT["TIME_PART"] = "(Maiúscula-)Clic ou arrastre para cambiar valor";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d/%m/%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%A, %e de %B de %Y";

Calendar._TT["WK"] = "sem";
Calendar._TT["TIME"] = "Hora:";
