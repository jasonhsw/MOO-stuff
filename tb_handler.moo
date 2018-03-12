@create $thing named traceback handler:traceback,handler
@corify traceback as $tb_handler
@prop $tb_handler."hue_code" {} r
;;$tb_handler.("hue_code") = {"if (!callers())", "  $tb_handler:(verb)(@args);", "  if (!$object_utils:connected(player))", "    \"Mail the player the traceback if e isn't connected.\";", "    \"$mail_agent:send_message(#0, player, {\\\"traceback\\\", $gripe_recipients}, args[5];\";", "  endif", "  \"now let the player do something with it if e wants...\";", "  `player:(verb)(@args) ! ANY';", "  return 1;", "endif", "\"Last modified Wed Aug 16 06:53:41 2017 CDT by Jason Perino (#92@ThetaCore).\";"}
@prop $tb_handler."help_msg" {} r
;;$tb_handler.("help_msg") = {"The traceback handler can be used globally, or it can be  used to catch only specific tracebacks.", "The verbs handle_uncaught_error and handle_task_timeout should only be called from #0, but anyone can format a traceback with the format_traceback verb.", "", "This object and all related code was originally written by Jason SantaAna-White.", "This  object and other MOO code is available from https://github.com/jasonhsw/MOO-stuff"}
;;$tb_handler.("aliases") = {"traceback", "handler"}
;;$tb_handler.("description") = "The traceback handler  abbreviates the traceback format, suppresses repeat lines, and shows verbcode where possible. See \"help $tb_handler\" for more information."
;;$tb_handler.("object_size") = {13225, 1502868355}
@verb $tb_handler:"handle_uncaught_error" this none this xd
@program $tb_handler:handle_uncaught_error
{code, msg, value, stack, traceback, ?cmd = ""} = args;
(caller != #0) && raise(E_PERM);
traceback = this:format_traceback(msg, stack, cmd, player);
for t in (traceback)
  notify(player, t);
endfor
return 1;
"Last modified Mon Mar 12 10:42:28 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $tb_handler:"format_traceback" this none this xd
@program $tb_handler:format_traceback
"$tb_handler:format_traceback(msg, tb_stack, last_command, privs) => List of strings";
"This verb is useful in creating a terser traceback format to output to the offending programmer/wizard,  or storage for later study, if the traceback was caused by a player.";
{msg, stack, cmd, ?privs = $nothing} = args;
(privs != $nothing) && set_task_perms(privs);
output = {};
repeats = 0;
curr_line = {};
for t in [1..length(stack)]
  if (stack[t] == curr_line)
    repeats = repeats + 1;
    continue;
  elseif (repeats && (stack[t] != curr_line))
    output[$ - (line ? 1 | 0)] = ((output[$ - (line ? 1 | 0)] + " [") + tostr(repeats)) + "]";
    repeats = 0;
  endif
  curr_line = stack[t];
  {vthis, vname, prog, vloc, vplayer, lnum} = curr_line;
  if (t == 1)
    output = {((this:get_task_desc(vloc, vname, prog, vthis, lnum) + ": ") + msg) + (cmd && ((" [CMD=" + cmd) + "]"))};
    curr_line = {};
  else
    output = {@output, "Via " + this:get_task_desc(vloc, vname, prog, vthis, lnum)};
  endif
  line = `verb_code(vloc, vname)[lnum] ! ANY => ""';
  if (line)
    output = {@output, line};
  endif
  $command_utils:suspend_if_needed(0);
endfor
if (repeats)
  output[$] = ((output[$] + " [") + tostr(repeats)) + "]";
  repeats = 0;
endif
output = {@output, "(END)"};
return output;
"Last modified Mon Mar 12 10:44:00 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $tb_handler:"get_task_desc*ription" this none this xd
@program $tb_handler:get_task_description
"$tb_handler:get_task_desc*ription(verb_name,verb_location,programmer,verb_this,line_number) => Task description";
"Creates a string describing the task, whether it is a built-in function, the line number and the value of this in the specified task.";
{verb_loc, verb_name, programmer, verb_this, line_number} = args;
builtin = 0;
desc = "";
if (((verb_loc == $nothing) && (programmer == $nothing)) && verb_name)
  builtin = 1;
  desc = verb_name + "()";
else
  verb_name = (!verb_name) ? "Eval input" | verb_name;
  verb_name = (length(verb_name) > 30) ? verb_name[1..30] | verb_name;
  if (verb_this != $nothing)
    desc = ($code_utils:corify_object(verb_loc) + ":") + verb_name;
  else
    desc = verb_name;
  endif
  desc = ((desc + "(") + tostr(line_number)) + ")";
endif
if (!builtin)
  if ((verb_this != $nothing) && (verb_this != verb_loc))
    desc = ((desc + " [") + tostr(verb_this)) + "]";
  endif
endif
return desc;
"Last modified Mon Mar 12 09:59:38 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $tb_handler:"handle_task_timeout" this none this xd
@program $tb_handler:handle_task_timeout
{resource, stack, traceback, ?cmd = ""} = args;
(caller != #0) && raise(E_PERM);
traceback = this:format_traceback("Out of " + resource, stack, cmd, player);
for t in (traceback)
  notify(player, t);
endfor
return 1;
"Last modified Mon Mar 12 10:42:16 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $tb_handler:"install" this none none
@program $tb_handler:install
if (!player.wizard)
  return player:Tell("This verb requires wizardly permissions to execute.");
endif
player:tell("This verb will finish installing the traceback handler by installing #0:\"handle_uncaught_error handle_task_timeout\". If verbs exist with those names, they will be backed up.");
if (!$command_utils:yes_or_no("Ok to proceed?"))
  return player:tell("Aborted.");
endif
player:tell("Beginning installation.");
for v in ({"handle_uncaught_error", "handle_task_timeout"})
  if ($object_utils:has_callable_verb($sysobj, v))
    player:tell(((("Renaming $" + v) + " to $") + v) + "_bak...");
    $code_utils:move_verb($sysobj, v, $sysobj, v + "_bak");
  endif
endfor
player:tell("Installing verb.");
add_verb($sysobj, {player, "rxd", "handle_uncaught_error handle_task_timeout"}, {"this", "none", "this"});
set_verb_code($sysobj, "handle_uncaught_error", this.hue_code);
player:tell("Installation complete.");
raise(E_NONE, "Traceback test");
"Last modified Mon Mar 12 10:10:23 2018 CDT by Jason Perino (#91@ThetaCore).";
.
"***finished***