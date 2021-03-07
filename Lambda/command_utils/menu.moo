@verb $command_utils:"menu" tnt rxd
@program $command_utils:menu
"    $command_utils:menu(lst opts, int read_method[, int start_number[, int permit_invalid]])";
"Opts should be a list containing either strings or lists.";
"    To use numerical menu options, you simply fill the opts list with strings, E.G.:";
"    $command_utils:menu({\"a\",\"b\",\"c\", ...}, 0);";
"    You can prepend any string within the opts list with an underline to make it a menu header. For example:";
"    $command_utils:menu({\"_Choices:\",\"Left\",\"Right\"},0);";
"    Would print:";
"    Choices:";
"    [1] Left";
"    [2] Right";
"    ";
"  You can also use a string with the ampersand (&) character before the letter you want to use as the menu option.";
"For example, \"R&eset password\" would print \"[E] Reset password\".";
"  ";
"If lists are found within the opts variable, the menu will display the output in a table, and the first element of opts will be used as the table headers.";
"In this case, only the first element of every sublist will be checked for special symbols.";
"    The read_method var has three valid values: 0, 1 and 2.";
"    When read_method is 0, the read() builtin will be used to get input.";
"    When read_method is set to 1, the $command_utils:read() verb will be used to get input.";
"    When read_method is 2, nothing else will happen, and the function will return 0.";
"  ";
" The start variable specifies what number to start from, so if you wanted to, you could have regular menu options start from number 18 instead of 1, for example.";
"  When the permit_invalid variable is false, and an invalid option is selected, the menu will be presented again and again, until the user has selected a valid option, or aborted the task, if that option is available (E.G. Using read method 1).";
{opts, ?rm = 1, ?start = 1, ?permit_invalid = 1} = args;
opt_output = opt_table = valid_opts = {};
if (typeof(opts[1]) == LIST)
  table = 1;
  headers = opts[1];
  opts = listdelete(opts, 1);
else
  table = 0;
endif
for o in (opts)
  if (typeof(o) == STR)
    o = {o};
  endif
  if (o[1][1] == "_")
    start= start - 1;
    o[1] = o[1][2..$];
    if (table)
      opt_table = {@opt_table, {"", @o}};
    else
      opt_output = {@opt_output, o[1]};
    endif
  elseif ((i = index(o[1], "&")) && i < length(o[1]))
    start = start - 1;
    char = $string_utils:capitalize(o[1][i + 1]);
    o[1] = o[1][1..i - 1] + o[1][i + 1..$];
    valid_opts = {@valid_opts, char};
    if (table)
      opt_table = {@opt_table, {"[" + char + "]", @o}};
    else
      opt_output = {@opt_output, "[" + char + "] " + o[1]};
    endif
  else
    valid_opts = {@valid_opts, start};
    if (table)
      opt_table = {@opt_table, {"[" + tostr(start) + "]", @o}};
    else
      opt_output = {@opt_output, "[" + tostr(start) + "] " + o[1]};
    endif
  endif
  start = start + 1;
endfor
if (table)
  width = toint(ceil(tofloat(length(tostr(start)) + 2) * 2.5));
  headers = {{"[#]", max(5, width), width - 2}, @headers};
  opt_output = $string_utils:table_left(headers, opt_table);
endif
while (1)
  for o in (opt_output)
    notify(player, o);
  endfor
  if (rm == 2)
    return;
  endif
  if (!rm)
    ret = read();
  elseif (rm == 1)
    ret = $command_utils:read();
  endif
  if ($string_utils:is_numeric(ret))
    ret = toint(ret);
  endif
  if (!(ret in valid_opts))
    notify(player, "Invalid selection.");
    if (permit_invalid)
      return $nothing;
    endif
  else
    return ret;
  endif
endwhile
"Last modified Wed Mar 28 11:47:37 2018 CDT by Jason Perino (#91@ThetaCore).";
.
