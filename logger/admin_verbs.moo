@verb $builder:"@logs" any none none d
@program $builder:@logs
"Usage: @logs [+|-]<log-spec>[/<level>][ <number-of-entries>]";
"View info channel logs or set log levels for one or more logs.";
"Typing @logs on its own will give you a list of available logs.";
"log-spec can be one or more log names, separated with a comma (,).";
what = $string_utils:explode(dobjstr, " ");
if (!what || length(what) > 2)
  "Invalid number of arguments.";
  player:tell("Usage: @logs [-|+]<log-spec>[/<level>][ <#>]");
  logs = $logger:all_logs();
  for l in [1..length(logs)]
    current_level = $logger:get_log_level_for(logs[l]);
    if (current_level != $logger.default_log_level)
      logs[l] = logs[l] + (current_level <= length($logger.log_levels) ? " [" + $string_utils:capitalize($logger.log_levels[current_level][1]) + "]" | " [/]");
    endif
    $command_utils:suspend_if_needed(0);
  endfor
  player:tell("Available logs: ");
  player:tell_lines($string_utils:columnize($LIST_UTILS:SORT(logs), 3, abs(player:linelen())));
  return player:tell("Log levels (in ascending order of severity): " + $string_utils:english_list($logger.log_levels, "(no levels defined)", " "));
endif
change = 0;
{logstr, ?entries = 10} = what;
logs = {};
entries = toint(entries);
if (entries < 1)
  return player:tell("Invalid number.");
endif
if (logstr[1] == "+" || logstr[1] == "-")
  "Player is changing ignore status for one or more logs.";
  if (logstr == "+" || logstr == "-")
    return player:tell("Usage: " + verb + " [+|-]<log-spec>[/<level>]");
  else
    change = logstr[1] == "+" ? 1 | -1;
    logstr = logstr[2..$];
  endif
endif
"Check for log level.";
l = index(logstr, "/");
if (l && length(logstr) > l)
  levels = $logger:match_log_level(logstr[l + 1..$]);
  if (!levels)
    return player:tell("No level matches for \"" + logstr[l + 1..$] + "\".");
  elseif (length(levels) > 1)
    return player:tell("Multiple level matches found for \"" + logstr[l + 1..$] + "\": " + $string_utils:english_list($list_utils:sort(levels)) + ".");
  else
    level_desc = levels[1];
    level = level_desc in $logger.log_levels;
  endif
  logstr = logstr[1..l - 1];
else
  if (l)
    logstr = logstr[1..l - 1];
  endif
  level = 0;
endif
logs = $string_utils:EXPLODE(logstr, ",");
if (logs)
  for l in [1..length(logs)]
    log_matches = $logger:match_log(logs[l]);
    if (!log_matches)
      return player:tell("No log matches for \"" + logs[l] + "\".");
    elseif (length(log_matches) > 1)
      return player:tell("Multiple log matches found for \"" + logs[l] + "\": " + $string_utils:english_list($list_utils:sort(log_matches)) + ".");
    else
      logs[l] = log_matches[1];
    endif
  endfor
endif
if (change)
  changed = unchanged = {};
  "Change log ignore status.";
  if (!logs)
    return player:tell("You must specify the name of at least one log.");
  endif
  for l in (logs)
    current_level = $logger:get_log_level_for(l);
    new_level = level;
    if (!new_level)
      if (change == 1 && current_level <= length($logger.log_levels))
        unchanged = {@unchanged, l + " (" + $string_utils:capitalize($logger.log_levels[current_level]) + ")"};
        continue;
      else
        new_level = $logger.default_log_level;
      endif
    endif
    if (change == -1 && current_level == length($logger.log_levels) + 1 || (change == 1 && current_level == new_level))
      unchanged = {@unchanged, l + (change == 1 ? " (" + $string_utils:capitalize($logger.log_levels[current_level]) + ")" | "")};
      continue;
    else
      $logger:set_log_level_for(l, change == -1 ? length($logger.log_levels) + 1 | new_level);
      changed = {@changed, l};
    endif
  endfor
  if (changed)
    if (!level)
      level = new_level;
    endif
    player:tell("Now " + (change == -1 ? "ignoring the " | "listening to  messages from the ") + $string_utils:english_list(changed) + (length(changed) == 1 ? " log" | " logs") + (change == 1 ? " with level >= " + $logger.log_levels[level] | "")
+ ".");
  endif
  if (unchanged)
    if (change == 1)
      player:tell("You're listening to " + (length(unchanged) == 1 ? "this log: " | "these logs: ") + $string_utils:english_list(unchanged) + ".");
    else
      player:tell("You're ignoring the " + $string_utils:english_list(unchanged) + (length(unchanged) == 1 ? " log." | " logs."));
    endif
  endif
else
  "Player is checking messages in one or more logs.";
  if (!level)
    if (length(logs) == 1)
      level = $logger:get_log_level_for(logs[1]);
      if (level < 1 || level > length($logger.log_levels))
        level = $logger.default_log_level;
      endif
    else
      level = $logger.default_log_level;
    endif
    level_desc = $logger.log_levels[level];
  endif
  msgs = $logger:get_log_messages(player, logs, entries, level);
  entries = length(msgs);
  if (!entries)
    return player:tell("No entries in " + (logs ? "the " + $string_utils:english_list(logs) + (length(logs) == 1 ? " log" | " logs") | "any log") + " with level >= " + level_desc + ".");
  endif
  player:tell("Last " + tostr(entries) + " " + (entries == 1 ? "entry" | "entries") + " from " + (logs ? "the " + $string_utils:english_list(logs) + (length(logs) == 1 ? " log" | " logs") | "all logs") + " (Level >= " + level_desc + "):");
  for l in (msgs)
    {?from = "", when, lvl, msg} = l;
    if (typeof(msg) == LIST)
      player:tell((from ? $string_utils:capitalize(from) + " - " | "") + ctime(when, 1) + " - " + $string_utils:capitalize($logger.log_levels[lvl]) + ":");
      player:tell_lines(msg);
    else
      player:tell((from ? $string_utils:capitalize(from) + " - " | "") + ctime(when) + " - " + $string_utils:capitalize($logger.log_levels[lvl]) + ": " + msg);
    endif
  endfor
endif
"Last modified Mon Mar 12 05:44:31 2018 CDT by Jason Perino (#91@ThetaCore).";
.