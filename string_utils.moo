@verb $string_utils:"table_left table_center table_centre table_right"   this none this xd
@program $string_utils:table_left
":table_left/table_center/table_centre/table_right(headers, data[, sep-char[, linelen]]): Return a list of strings representing the provided headers and table data.";
"Each element of the headers list can be a string of the header content, or a list containing the header content, the length of the column, and the (optional) length limit of the field content.";
"By default, the length of each column is determined by dividing linelen by the number of headers.";
"If column length is less than 0, the column length will be taken as a percentage. So -20 would cause the column to take up 20% of linelen.";
"If column length is greater than 0, the column will take up exactly that number of characters.";
"The default content length for each field is 87.5% of the column length, except for the last column, which (by default) has no column or content limits (other than the limit set by linelen).";
"Content length is specified exactly the same way as column length, except that percentages are taken as x% of column length, rather than linelen.";
"The data list should consist of lists containing one ore more elements. Think of the sublists as rows, and the elements within them as the column fields.";
"If there are less fields than there are headers, the last field in the row will not expand to fill the rest of the line. The line will end at the end of the last available field in that row.";
"If you wish to have blank fields included in the middle of a row, you will have to include them in the correct positions.";
"If sep-char is provided, it will be used to create a separator after the headers and before the content, and another after the content.";
"By default, linelen is set to player:linelen(), or 79 on error.";
"Raises E_INVARG if the combined length of the columns exceeds linelen, or if invalid values are provided for the column or content limits of any of the columns.";
"";
"... I know this could probably be more efficient, so if you think you can make it less tick hungry, go for it.";
{headers, data, ?sep = "", ?linelen = `abs(player:linelen()) ! ANY => 79'} = args;
align = verb[7..$];
!headers || typeof(headers) != LIST || typeof(data) != LIST || typeof(sep) != STR || typeof(linelen) != INT || linelen < 40 && raise(E_INVARG);
used = 0;
free = linelen;
auto_length_headers = length(headers);
for h in [1..length(headers)]
  "Make sure headers are properly set up, and check for headers with fixed lengths.";
  if (typeof(headers[h]) == STR)
    headers[h] = {headers[h], 0, 0};
  elseif (length(headers[h]) < 3)
    for f in [1..3 - length(headers[h])]
      headers[h] = {@headers[h], 0};
    endfor
  endif
  {column_length, content_length} = headers[h][2..$];
  if (column_length > 0)
    column_length < 2 || column_length > free && raise(E_INVARG);
    auto_length_headers = auto_length_headers - 1;
   free = free -  column_length;
    used = used + column_length;
  endif
  $command_utils:suspend_if_needed(0);
endfor
for h in [1..length(headers)]
  {column_length, content_length} = headers[h][2..$];
  column_length < -100 || content_length < -100 && raise(E_INVARG);
  "check for columns whose widths are set to percentages of linelen.";
  if (column_length < 0)
    auto_length_headers = auto_length_headers - 1;
    column_length = toint(tofloat(linelen) * ((tofloat(column_length) - tofloat(column_length) * 2.0) / 100.0));
    headers[h][2] = column_length;
    column_length < 2 || column_length > free && raise(E_INVARG);
    used = used + column_length;
    free = free - column_length;
  endif
  $command_utils:suspend_if_needed(0);
endfor
"We had to check for static and percentage-based header sizes first, so that we know how much room we have left to work with for autosized headers.";
"We can finally deal with content lengths here as well.";
for h in [1..length(headers)]
  {column_length, content_length} = headers[h][2..$];
  if (!column_length)
    column_length = headers[h][2] = h != length(headers) ? free / auto_length_headers | linelen - used;
    used = used + column_length;
  endif
  if (content_length < 0)
    content_length = toint(tofloat(column_length) * ((tofloat(content_length) - tofloat(content_length) * 2.0) / 100.0));
    headers[h][3] = content_length;
  elseif (!content_length)
    content_length = headers[h][3] = toint(tofloat(column_length) * 0.875);
  endif
  content_length < 1 || content_length > column_length && raise(E_INVARG);
  $command_utils:suspend_if_needed(0);
endfor
free = linelen - used;
"Build the table.";
table = {};
head = "";
for h in (headers)
  {title, column_length, content_length} = h;
  head = head + $string_utils:(align)(title[1..min(content_length, $)], column_length);
endfor
table = {@table, head};
if (sep)
  table = {@table, $string_utils:space(linelen, sep)};
endif
for d in [1..length(data)]
  typeof(data[d]) != LIST && raise(E_INVARG);
  "if (length(data) < length(headers))";
  "  for f in [1..length(headers) - length(data[d])]";
  "    data[d] = {@data[d], \"\"};";
  "  endfor";
  "endif";
  row = "";
  for r in [1..length(data[d])]
    if (r <= length(headers))
      row = row + $string_utils:(align)(tostr(data[d][r])[1..min(headers[r][3], $)], headers[r][2]);
    endif
    $command_utils:suspend_if_needed(0);
  endfor
  table = {@table, row};
  $command_utils:suspend_if_needed(0);
endfor
if (sep)
  table = {@table, $string_utils:space(linelen, sep)};
endif
return table;
"Last modified Mon Mar 12 09:08:12 2018 CDT by Jason Perino (#91@ThetaCore).";
.
