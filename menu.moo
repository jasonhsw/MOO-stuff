@verb $command_utils:"menu" this none this rxd
@program $command_utils:menu
"    $command_utils:menu(lst opts, int read_method[, int start_number[, int permit_invalid]])";
"    opts can be filled with strings, sublists with two strings, or a combination of both.";
"    To use numerical menu options, you simply fill the opts list with strings, E.G.:";
"    $command_utils:menu({\"a\",\"b\",\"c\", ...}, 0);";
"    You can prepend any string within the opts list with an underline to make it a menu header. For example:";
"    $command_utils:menu({\"_Choices:\",\"Left\",\"Right\"},0);";
"    Would print:";
"    Choices:";
"    [1] Left";
"    [2] Right";
"    ";
"    The sublist method is useful for using letters as menu options. E.G.: $command_utils:menu({{\"A\",\"Alpha\"},{\"B\",\"Bravo\"},{\"C\",\"Charley\"}},0); would print:";
"    [A] Alpha";
"    [B] Bravo";
"    [C] Charley";
"    ";
"  You can also use a string with the ampersand (&) character before the letter you want to use as the menu option.";
"  For example, instead of one of the options being {\"e\", \"Reset password\"}, you could simply use \"R&eset password\"";
"  ";
"    The read_method var has three valid values: 0, 1 and 2.";
"    When read_method is 0, the read() builtin will be used to get input.";
"    When read_method is set to 1, the $command_utils:read() verb will be used to get input.";
"    When read_method is 2, nothing else will happen, and the function will return 0.";
"  ";
" The start variable specifies what number to start from, so if you wanted to, you could have regular menu options start from number 18 instead of 1, for example.";
"  When the permit_invalid variable is false, and an invalid option is selected, the menu will be presented again and again, until the user has selected a valid option, or aborted the task, if that option is available (E.G. Using read method 1).";
{opts, rm, ?start = 1, ?permit_invalid = 1} = args;
opt_list = {};
valid_opts = {};
for o in [1..length(opts)]
  if (typeof(opts[o]) == STR && index(opts[o], "&"))
    i = index(opts[o], "&");
    if (!i || i >= length(opts[o]))
      continue;
    else
      opt_char = $string_utils:capitalize(opts[o][i + 1]);
      opts[o] = `opts[o][1..i - 1] ! ANY => ""' + `opts[o][i + 1..$] ! ANY => ""';
      opt = "[" + opt_char + "] " + opts[o];
      valid_opts = {@valid_opts, opt_char};
    endif
  elseif (typeof(opts[o]) == LIST)
    opt = "[" + $string_utils:capitalize(opts[o][1]) + "] " + opts[o][2];
    valid_opts = {@valid_opts, opts[o][1]};
  else
    if (typeof(opts[o]) == STR && opts[o][1] == "_")
      start= start - 1;
      opt = opts[o][2..$];
    else
      if (typeof(opts[o]) == OBJ)
        opt = "[" + tostr(start) + "] " + opts[o]:titlec();
      else
        opt = "[" + tostr(start) + "] " + opts[o];
      endif
      valid_opts = setadd(valid_opts, start);
    endif
  endif
  opt_list = {@opt_list, opt};
  start = start + 1;
endfor
while (1)
  for o in (opt_list)
    `player:tell(o) ! ANY => notify(player, o)';
  endfor
  if (!rm)
    ret = read();
  elseif (rm == 1)
    ret = $command_utils:read();
  else
    return;
  endif
  if ((num = $code_utils:toint(ret)) != E_TYPE)
    ret = num;
  endif
  if (!(ret in valid_opts))
    `player:tell("Invalid selection.") ! ANY => notify(player, "Invalid selection.")';
    if (permit_invalid)
      return $nothing;
    endif
  else
    return ret;
  endif
endwhile
"Last modified Mon Jan 23 22:12:24 2012 CST by Coderunner Jason Perino (#97@ThetaCore).";
.
