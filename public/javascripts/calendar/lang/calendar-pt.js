// ** I18N

// Calendar pt language
// Author: Adalberto Machado, <betosm@terra.com.br>
// Corrected by: Pedro Araújo <phcrva19@hotmail.com>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Domingo",
 "Segunda",
 "Terça",
 "Quarta",
 "Quinta",
 "Sexta",
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
 "Seg",
 "Ter",
 "Qua",
 "Qui",
 "Sex",
 "Sáb",
 "Dom");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Janeiro",
 "Fevereiro",
 "Março",
 "Abril",
 "Maio",
 "Junho",
 "Julho",
 "Agosto",
 "Setembro",
 "Outubro",
 "Novembro",
 "Dezembro");

// short month names
Calendar._SMN = new Array
("Jan",
 "Fev",
 "Mar",
 "Abr",
 "Mai",
 "Jun",
 "Jul",
 "Ago",
 "Set",
 "Out",
 "Nov",
 "Dez");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Sobre o calendário";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"Última versão visite: http://www.dynarch.com/projects/calendar/\n" +
"Distribuído sobre a licença GNU LGPL.  Veja http://gnu.org/licenses/lgpl.html para detalhes." +
"\n\n" +
"Selecção de data:\n" +
"- Use os botões \xab, \xbb para seleccionar o ano\n" +
"- Use os botões " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " para seleccionar o mês\n" +
"- Segure o botão do rato em qualquer um desses botões para selecção rápida.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Selecção de hora:\n" +
"- Clique em qualquer parte da hora para incrementar\n" +
"- ou Shift-click para decrementar\n" +
"- ou clique e segure para selecção rápida.";

Calendar._TT["PREV_YEAR"] = "Ano ant. (segure para menu)";
Calendar._TT["PREV_MONTH"] = "Mês ant. (segure para menu)";
Calendar._TT["GO_TODAY"] = "Hoje";
Calendar._TT["NEXT_MONTH"] = "Prox. mês (segure para menu)";
Calendar._TT["NEXT_YEAR"] = "Prox. ano (segure para menu)";
Calendar._TT["SEL_DATE"] = "Seleccione a data";
Calendar._TT["DRAG_TO_MOVE"] = "Arraste para mover";
Calendar._TT["PART_TODAY"] = " (hoje)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Mostre %s primeiro";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Fechar";
Calendar._TT["TODAY"] = "Hoje";
Calendar._TT["TIME_PART"] = "(Shift-)Click ou arraste para mudar valor";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d/%m/%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %e %b";

Calendar._TT["WK"] = "sm";
Calendar._TT["TIME"] = "Hora:";
