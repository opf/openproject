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
("Niedziela",
 "Poniedziałek",
 "Wtorek",
 "Środa",
 "Czwartek",
 "Piątek",
 "Sobota",
 "Niedziela");

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
("Nie",
 "Pon",
 "Wto",
 "Śro",
 "Czw",
 "Pią",
 "Sob",
 "Nie");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Styczeń",
 "Luty",
 "Marzec",
 "Kwiecień",
 "Maj",
 "Czerwiec",
 "Lipiec",
 "Sierpień",
 "Wrzesień",
 "Październik",
 "Listopad",
 "Grudzień");

// short month names
Calendar._SMN = new Array
("Sty",
 "Lut",
 "Mar",
 "Kwi",
 "Maj",
 "Cze",
 "Lip",
 "Sie",
 "Wrz",
 "Paź",
 "Lis",
 "Gru");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "O kalendarzu";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"Po ostatnią wersję odwiedź: http://www.dynarch.com/projects/calendar/\n" +
"Rozpowszechniany pod licencją GNU LGPL.  Zobacz: http://gnu.org/licenses/lgpl.html z celu zapoznania się ze szczegółami." +
"\n\n" +
"Wybór daty:\n" +
"- Użyj \xab, \xbb przycisków by zaznaczyć rok\n" +
"- Użyj " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " przycisków by zaznaczyć miesiąc\n" +
"- Trzymaj wciśnięty przycisk myszy na każdym z powyższych przycisków by przyśpieszyć zaznaczanie.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Wybór czasu:\n" +
"- Kliknij na każdym przedziale czasu aby go powiększyć\n" +
"- lub kliknij z przyciskiem Shift by go zmniejszyć\n" +
"- lub kliknij i przeciągnij dla szybszego zaznaczenia.";

Calendar._TT["PREV_YEAR"] = "Poprz. rok (przytrzymaj dla menu)";
Calendar._TT["PREV_MONTH"] = "Poprz. miesiąc (przytrzymaj dla menu)";
Calendar._TT["GO_TODAY"] = "Idź do Dzisiaj";
Calendar._TT["NEXT_MONTH"] = "Następny miesiąc(przytrzymaj dla menu)";
Calendar._TT["NEXT_YEAR"] = "Następny rok (przytrzymaj dla menu)";
Calendar._TT["SEL_DATE"] = "Zaznacz datę";
Calendar._TT["DRAG_TO_MOVE"] = "Przeciągnij by przenieść";
Calendar._TT["PART_TODAY"] = " (dzisiaj)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Pokaż %s pierwszy";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Zamknij";
Calendar._TT["TODAY"] = "Dzisiaj";
Calendar._TT["TIME_PART"] = "(Shift-)Kliknij lub upuść by zmienić wartość";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%R-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Czas:";
