// ** I18N

// Calendar EU language
// Author: Ales Zabala Alava (Shagi), <shagi@gisa-elkartea.org>
// 2010-01-25
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Igandea",
 "Astelehena",
 "Asteartea",
 "Asteazkena",
 "Osteguna",
 "Ostirala",
 "Larunbata",
 "Igandea");

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
("Ig.",
 "Al.",
 "Ar.",
 "Az.",
 "Og.",
 "Or.",
 "La.",
 "Ig.");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("Urtarrila",
 "Otsaila",
 "Martxoa",
 "Apirila",
 "Maiatza",
 "Ekaina",
 "Uztaila",
 "Abuztua",
 "Iraila",
 "Urria",
 "Azaroa",
 "Abendua");

// short month names
Calendar._SMN = new Array
("Urt",
 "Ots",
 "Mar",
 "Api",
 "Mai",
 "Eka",
 "Uzt",
 "Abu",
 "Ira",
 "Urr",
 "Aza",
 "Abe");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Egutegiari buruz";

Calendar._TT["ABOUT"] =
"DHTML Data/Ordu Hautatzailea\n" +
"(c) dynarch.com 2002-2005 / Egilea: Mihai Bazon\n" + // don't translate this this ;-)
"Azken bertsiorako: http://www.dynarch.com/projects/calendar/\n" +
"GNU LGPL Lizentziapean banatuta. Ikusi http://gnu.org/licenses/lgpl.html zehaztasunentzako." +
"\n\n" +
"Data hautapena:\n" +
"- Erabili \xab, \xbb botoiak urtea hautatzeko\n" +
"- Erabili " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " botoiak hilabeteak hautatzeko\n" +
"- Mantendu saguaren botoia edo goiko edozein botoi hautapena bizkortzeko.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Ordu hautapena:\n" +
"- Klikatu orduaren edozein zati handitzeko\n" +
"- edo Shift-klikatu txikiagotzeko\n" +
"- edo klikatu eta arrastatu hautapena bizkortzeko.";

Calendar._TT["PREV_YEAR"] = "Aurreko urtea (mantendu menuarentzako)";
Calendar._TT["PREV_MONTH"] = "Aurreko hilabetea (mantendu menuarentzako)";
Calendar._TT["GO_TODAY"] = "Joan Gaur-era";
Calendar._TT["NEXT_MONTH"] = "Hurrengo hilabetea (mantendu menuarentzako)";
Calendar._TT["NEXT_YEAR"] = "Hurrengo urtea (mantendu menuarentzako)";
Calendar._TT["SEL_DATE"] = "Data hautatu";
Calendar._TT["DRAG_TO_MOVE"] = "Arrastatu mugitzeko";
Calendar._TT["PART_TODAY"] = " (gaur)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Erakutsi %s lehenbizi";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Itxi";
Calendar._TT["TODAY"] = "Gaur";
Calendar._TT["TIME_PART"] = "(Shift-)Klikatu edo arrastatu balioa aldatzeko";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Ordua:";
