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
("Pazar",
 "Pazartesi",
 "Salı",
 "Çarşamba",
 "Perşembe",
 "Cuma",
 "Cumartesi",
 "Pazar");

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
("Paz",
 "Pzt",
 "Sal",
 "Çar",
 "Per",
 "Cum",
 "Cmt",
 "Paz");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Ocak",
 "Şubat",
 "Mart",
 "Nisan",
 "Mayıs",
 "Haziran",
 "Temmuz",
 "Ağustos",
 "Eylül",
 "Ekim",
 "Kasım",
 "Aralık");

// short month names
Calendar._SMN = new Array
("Oca",
 "Şub",
 "Mar",
 "Nis",
 "May",
 "Haz",
 "Tem",
 "Ağu",
 "Eyl",
 "Eki",
 "Kas",
 "Ara");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Takvim hakkında";

Calendar._TT["ABOUT"] =
"DHTML Tarih/Zaman Seçici\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Tarih Seçimi:\n" +
"- Yıl seçmek için \xab, \xbb tuşlarını kullanın\n" +
"- Ayı seçmek için " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " tuşlarını kullanın\n" +
"- Hızlı seçim için yukardaki butonların üzerinde farenin tuşuna basılı tutun.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Zaman Seçimi:\n" +
"- Arttırmak için herhangi bir zaman bölümüne tıklayın\n" +
"- ya da azaltmak için Shift+tıkla yapın\n" +
"- ya da daha hızlı bir seçim için tıklayın ve sürükleyin.";

Calendar._TT["PREV_YEAR"] = "Öncki yıl (Menu için basılı tutun)";
Calendar._TT["PREV_MONTH"] = "Önceki ay (Menu için basılı tutun)";
Calendar._TT["GO_TODAY"] = "Bugüne Git";
Calendar._TT["NEXT_MONTH"] = "Sonraki Ay (Menu için basılı tutun)";
Calendar._TT["NEXT_YEAR"] = "Next year (Menu için basılı tutun)";
Calendar._TT["SEL_DATE"] = "Tarih seçin";
Calendar._TT["DRAG_TO_MOVE"] = "Taşımak için sürükleyin";
Calendar._TT["PART_TODAY"] = " (bugün)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "%s : önce göster";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "1,0";

Calendar._TT["CLOSE"] = "Kapat";
Calendar._TT["TODAY"] = "Bugün";
Calendar._TT["TIME_PART"] = "Değeri değiştirmek için (Shift-)tıkla veya sürükle";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d-%m-%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "Hafta";
Calendar._TT["TIME"] = "Saat:";
