@create $generic_utils named pagination utilities:pagination,utilities
@corify pagination as $page_utils
;;$page_utils.("help_msg") = {"$page_utils:belongs_to(item_number, page_length): Returns the page that item_number belongs to when items are in reverse order.", "$page_utils:min_item(page, length): Returns the first item that belongs to page.", "$page_utils:max_item(page, page_length[, max-items]): Returns the last item that belongs to page.", "$page_utils:max_pages(max-items, page-length): Returns the number of pages.", "$page_utils:get_item_reversed(item, page, page_length, max-items): Returns the index of item in page when items are in reverse order.", "$page_utils:min_item_reversed(page, page-length, max-items): Returns the first item belonging to page.", "$page_utils:max_item_reversed(page, page-length, max-items): Returns the last item belonging to page.", "$page_utils:get_item(item, page, page-length): Return the index of the item in page.", "$page_utils:belongs_to_reversed(item_number, page_length, max_items): Returns the page that item_number belongs to, when items are in reverse order.", "", "This object and all related code was originally written by Jason SantaAna-White.", "This  object and other MOO code is available from https://github.com/jasonhsw/MOO-stuff"}
;;$page_utils.("aliases") = {"pagination", "utilities"}
;;$page_utils.("description") = "This is a placeholder parent for all the $..._utils packages, to more easily find them and manipulate them. At present this object defines no useful verbs or properties. (Filfre.)"
;;$page_utils.("object_size") = {5757, 1513702279}
@verb $page_utils:"belongs_to" this none this
@program $page_utils:belongs_to
"$page_utils:belongs_to(item_number, page_length): Returns the page that item_number belongs to when items are in reverse order.";
{item, length} = args;
return toint(((tofloat(item) - 1.0) / tofloat(length)) + 1.0);
"Last modified Tue Mar 27 15:18:01 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"min_item" this none this
@program $page_utils:min_item
"$page_utils:min_item(page, length): Returns the first item that belongs to page.";
{page, length} = args;
return toint(((tofloat(page) - 1.0) * tofloat(length)) + 1.0);
"Last modified Tue Mar 27 15:13:38 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"max_item" this none this
@program $page_utils:max_item
"$page_utils:max_item(page, page_length[, max-items]): Returns the last item that belongs to page.";
{page, length, ?max_items = 0} = args;
max = page * length;
if ((max_items > 0) && (max > max_items))
  max = max_items;
endif
return max;
"Last modified Tue Mar 27 15:14:30 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"max_pages" this none this xd
@program $page_utils:max_pages
"$page_utils:max_pages(max-items, page-length): Returns the number of pages.";
{items, length} = args;
return toint(ceil(tofloat(items) / tofloat(length)));
"Last modified Tue Mar 27 15:32:49 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"get_item_reversed" this none this xd
@program $page_utils:get_item_reversed
"$page_utils:get_item_reversed(item, page, page_length, max-items): Returns the index of item in page when items are in reverse order.";
"For example, if you want to display pages of news articles in a reverse chronological order.";
{item, page, pagelen, max_items} = args;
return ((max_items - ((page - 1) * pagelen)) - item) + 1;
"Last modified Tue Mar 27 15:32:38 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"min_item_reversed" this none this
@program $page_utils:min_item_reversed
"$page_utils:min_item_reversed(page, page-length, max-items): Returns the first item belonging to page.";
{page, pagelen, max_items} = args;
return max_items - ((page - 1) * pagelen);
"Last modified Tue Mar 27 15:32:09 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"max_item_reversed" this none this
@program $page_utils:max_item_reversed
"$page_utils:max_item_reversed(page, page-length, max-items): Returns the last item belonging to page.";
{page, pagelen, max_items} = args;
ret = (max_items - (page * pagelen)) + 1;
if (ret < 1)
  ret = 1;
endif
return ret;
"Last modified Tue Mar 27 15:31:56 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"get_item" this none this
@program $page_utils:get_item
"$page_utils:get_item(item, page, page-length): Return the index of the item in page.";
{item, page, pagelen} = args;
return ((page - 1) * pagelen) + item;
"Last modified Tue Mar 27 15:31:44 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $page_utils:"belongs_to_reversed" this none this
@program $page_utils:belongs_to_reversed
"$page_utils:belongs_to_reversed(item_number, page_length, max_items): Returns the page that item_number belongs to, when items are in reverse order.";
{item, length, max_items} = args;
item = max_items - (item - 1);
return toint(((tofloat(item) - 1.0) / tofloat(length)) + 1.0);
"Last modified Tue Mar 27 15:33:35 2018 CDT by Jason Perino (#91@ThetaCore).";
.
"***finished***
