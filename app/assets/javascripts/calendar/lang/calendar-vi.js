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
("Chủ nhật",
 "Thứ Hai",
 "Thứ Ba",
 "Thứ Tư",
 "Thứ Năm",
 "Thứ Sáu",
 "Thứ Bảy",
 "Chủ Nhật");

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
("C.Nhật",
 "Hai",
 "Ba",
 "Tư",
 "Năm",
 "Sáu",
 "Bảy",
 "C.Nhật");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Tháng Giêng",
 "Tháng Hai",
 "Tháng Ba",
 "Tháng Tư",
 "Tháng Năm",
 "Tháng Sáu",
 "Tháng Bảy",
 "Tháng Tám",
 "Tháng Chín",
 "Tháng Mười",
 "Tháng M.Một",
 "Tháng Chạp");

// short month names
Calendar._SMN = new Array
("Mmột",
 "Hai",
 "Ba",
 "Tư",
 "Năm",
 "Sáu",
 "Bảy",
 "Tám",
 "Chín",
 "Mười",
 "MMột",
 "Chạp");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Giới thiệu";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector (c) dynarch.com 2002-2005 / Tác giả: Mihai Bazon. " + // don't translate this this ;-)
"Phiên bản mới nhất có tại: http://www.dynarch.com/projects/calendar/. " +
"Sản phẩm được phân phối theo giấy phép GNU LGPL. Xem chi tiết tại http://gnu.org/licenses/lgpl.html." +
"\n\n" +
"Chọn ngày:\n" +
"- Dùng nút \xab, \xbb để chọn năm\n" +
"- Dùng nút " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " để chọn tháng\n" +
"- Giữ chuột vào các nút trên để có danh sách năm và tháng.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Chọn thời gian:\n" +
"- Click chuột trên từng phần của thời gian để chỉnh sửa\n" +
"- hoặc nhấn Shift + click chuột để tăng giá trị\n" +
"- hoặc click chuột và kéo (drag) để chọn nhanh.";

Calendar._TT["PREV_YEAR"] = "Năm trước (giữ chuột để có menu)";
Calendar._TT["PREV_MONTH"] = "Tháng trước (giữ chuột để có menu)";
Calendar._TT["GO_TODAY"] = "đến Hôm nay";
Calendar._TT["NEXT_MONTH"] = "Tháng tới (giữ chuột để có menu)";
Calendar._TT["NEXT_YEAR"] = "Ngày tới (giữ chuột để có menu)";
Calendar._TT["SEL_DATE"] = "Chọn ngày";
Calendar._TT["DRAG_TO_MOVE"] = "Kéo (drag) để di chuyển";
Calendar._TT["PART_TODAY"] = " (hôm nay)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Hiển thị %s trước";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Đóng";
Calendar._TT["TODAY"] = "Hôm nay";
Calendar._TT["TIME_PART"] = "Click, shift-click hoặc kéo (drag) để đổi giá trị";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Time:";
