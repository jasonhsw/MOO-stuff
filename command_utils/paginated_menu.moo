@verb $command_utils:"paginated_menu" tnt rxd
@program $command_utils:paginated_menu
":paginated_menu(page-length, start-page, item-callback, max-items[, reverse[, menu-title[, table-headers[, special-options]]]]): Display a menu of items, split into pages of page-length items.";
"Page-length is the number of items to display per page, and start-page is the number of the page to start on.";
"Item-callback should be either a string or a list containing the object and verbname to call to retrieve the item description to show in the menu. If a string is passed, caller will be used as the object to call.";
"The menu will call this verb with an item index as its argument. The return of the callback should be either a string, or a list of strings, depending on whether or not you want the menu to be displayed as a table.";
"Max-items refers to the maximum number of items available to the menu. It should be either an integer or a callback, as described above. The callback should return an integer.";
"If reverse is true, the items will be requested and displayed in reverse, highest to lowest.";
"Menu-title should be a string containing a message to be displayed at the top of the menu. You may use %p to refer to the current page number, and %m to refer to the maximum number of pages.";
"If you want the menu to be displayed as a table, table-headers should be a list containing table headers, as described in the documentation for $string_utils:table_left.";
"If you pass any fixed or percentage based header lengths, you should leave enough room for the item number header, which will be inserted by the menu.";
"Special-options should be a list of options to add to the menu after the page items, and before the page options.";
"\"previous page\", \"next page\", \"go to page\", and \"exit\" options are are inserted where appropriate, so don't supply any conflicting options.";
"Returns the item index if an item on the page was selected, or a list containing the number of the page that the player was on when they made their selection, and the special option that was selected.";
{pagelen, page, item_call, max_items, ?reverse = 0, ?title = "", ?headers = {}, ?special_opts = {}} = args;
`set_task_perms($no_one) ! ANY';
typeof(pagelen) != INT || pagelen < 1 || typeof(page) != INT || page < 1 || (typeof(item_call) != STR && typeof(item_call) != LIST) && raise(E_INVARG);
typeof(special_opts) != LIST || typeof(headers) != LIST || typeof(reverse) != INT && raise(E_INVARG);
reverse && !max_items && raise(E_INVARG);
if (typeof(item_call) == STR)
  item_call = {caller, item_call};
endif
if (typeof(max_items) == STR)
  max_items = {caller, max_items};
endif
if (typeof(max_items) == LIST)
  max_call = max_items;
  max_items = 0;
else
  max_call = {};
endif
while (1)
  ret = #-1;
  opts = (headers ? {headers} | {});
  if (max_call)
    max_items = max_call[1]:(max_call[2])();
    typeof(max_items) != INT || max_items < 1 && raise(E_INVARG);
  endif
  max_pages = $page_utils:max_pages(max_items, pagelen);
  if (!reverse)
    min_item = $page_utils:min_item(page, pagelen);
    max_item = $page_utils:max_item(page, pagelen, max_items);
  else
    min_item = $page_utils:min_item_reversed(page, pagelen, max_items);
    max_item = $page_utils:max_item_reversed(page, pagelen, max_items);
  endif
  o = min_item;
  while (min_item < max_item && o <= max_item || o >= max_item)
    item = item_call[1]:(item_call[2])(o);
    typeof(item) != STR && typeof(item) != LIST && raise(E_INVARG);
    opts = {@opts, item};
    o = o + ((max_item < min_item) ? -1 | 1);
    $command_utils:suspend_if_needed(0);
  endwhile
  opts = {@opts, "_Options:", @special_opts};
  if (page > 1)
    opts = {@opts, "&Previous page"};
  endif
  if (page < max_pages)
    opts = {@opts, "&Next page"};
  endif
  if (max_pages > 1)
    opts = {@opts, "&Go to page"};
  endif
  opts = {@opts, "E&xit"};
  while (ret == #-1)
    if (title)
      real_title = $string_utils:substitute(title, {{"%p", tostr(page)}, {"%m", tostr(max_pages)}});
      if (valid(player))
        player:tell(real_title);
      else
        notify(player, real_title);
      endif
    endif
    ret = $command_utils:menu(opts, valid(player));
    if (typeof(ret) == INT && ret >= 1 && ret <= pagelen)
      if (!reverse)
        index = $page_utils:get_item(ret, page, pagelen);
      else
        index = $page_utils:get_item_reversed(ret, page, pagelen, max_items);
      endif
      return index;
    elseif (ret == "p")
      page = page - 1;
    elseif (ret == "n")
      page = page + 1;
    elseif (ret == "g")
      if (valid(player))
        new_page = toint($command_utils:read("the page number"));
      else
        notify(player, "Enter the page number:");
        new_page = toint(read());
      endif
      if (new_page >= 1 && new_page <= max_pages)
        page = new_page;
      else
        if (valid(player))
          player:tell("Invalid page.");
        else
          notify(player, "Invalid page.");
        endif
      endif
    elseif (typeof(ret) == STR)
      return {page, ret};
    endif
  endwhile
endwhile
"Last modified Wed Mar 28 12:11:04 2018 CDT by Jason Perino (#91@ThetaCore).";
.
