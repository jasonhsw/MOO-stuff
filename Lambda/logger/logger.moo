@create $root_class named logger:logger
@corify logger as $logger
@prop $logger."max_log_length" 5000 ""
@prop $logger."log_levels" {} ""
;;$logger.("log_levels") = {"debug", "info", "notice", "warning", "alert", "error", "critical", "emergency"}
@prop $logger."default_log_level" 2 ""
@prop $logger."default_log_audience" 4 ""
@prop $logger."help_msg" {} r
;;$logger.("help_msg") = {"The logger object stores log messages on properties on itself. The properties have the form {audience, {message-list}}", "Audience is an integer. Either 1 (players), 2 (builders), 3 (programmers), or 4 (wizards only.)", "The message list contains lists of the form {timestamp, level, message}", "Level is an integer which refers to a log level in the log_levels property.", "$logger:(level)(log, message): log a message.", "Where level is one of the defined log levels.", "", "An administrator can change the level of messages that they receive from a log, or ignore a log completely with the @logs command.", "", "This object and all related code was originally written by Jason SantaAna-White.", "This  object and other MOO code is available from https://github.com/jasonhsw/MOO-stuff"}
;;$logger.("aliases") = {"logger"}
;;$logger.("description") = "The logger object stores messages for many different logs, and controls who can view those logs. Type \"help $logger\" for more information."
;;$logger.("object_size") = {13973, 1520852601}
@verb $logger:"broadcast" this none this xd
@program $logger:broadcast
":broadcast(message, audience): Tell all members of audience a message.";
{msg, ?audience = $logger.default_log_audience} = args;
plrs = connected_players();
for p in (plrs)
  if ((((audience == 4) && (!p.wizard)) || ((audience == 3) && (!p.programmer))) || ((audience == 2) && (!$object_utils:isa(p, $builder))))
    plrs = setremove(plrs, p);
  endif
endfor
if (plrs)
  for p in (plrs)
    p:tell(msg);
  endfor
endif
"Last modified Mon Mar 12 04:26:30 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"all_logs" this none this xd
@program $logger:all_logs
":all_logs(who): Returns a list of all logs readable by who.";
{?who = player} = args;
(!caller_perms().wizard) && raise(E_PERM);
(!$object_utils:isa(who, $player)) && raise(E_PERM);
logs = {};
for p in (properties(this))
  if ((`p[$ - 3..$] ! ANY => ""' == "_log") && this:is_log_readable_by(who, p[1..$ - 4]))
    logs = {@logs, p[1..$ - 4]};
  endif
  $command_utils:suspend_if_needed(0);
endfor
return logs;
"Last modified Mon Mar 12 04:22:42 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"match_log" this none this xd
@program $logger:match_log
":match_log([who,] log): Find all matching logs readable by who.";
{?who = player, log} = args;
(!caller_perms().wizard) && raise(E_PERM);
(!$object_utils:isa(who, $player)) && raise(E_INVARG);
matches = {};
if (!log)
  return matches;
endif
for l in (this:all_logs(who))
  if (this:is_log_readable_by(who, l) && ((log == l) || index(l, log)))
    matches = {@matches, l};
  endif
endfor
return matches;
"Last modified Mon Mar 12 04:24:23 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"debug info notice warning alert error critical emergency" this none this xd
@program $logger:debug
":(level)(title, msg): Write a message to a log.";
{title, msg} = args;
(!caller_perms().wizard) && raise(E_PERM);
level = verb in this.log_levels;
level_desc = $string_utils:capitalize(verb);
if ((typeof(msg) == LIST) && (length(msg) == 1))
  msg = msg[1];
endif
if (!$object_utils:has_property(this, title + "_log"))
  add_property(this, title + "_log", {this.default_log_audience, {}}, {#2, ""});
endif
this.(title + "_log")[2] = {@this.(title + "_log")[2], {time(), level, msg}};
if (length(this.(title + "_log")[2]) > this.max_log_length)
  this.(title + "_log")[2] = this.(title + "_log")[2][$ - (this.max_log_length - 1)..$];
endif
audience = this:get_log_audience(title);
players = connected_players();
for p in (players)
  "Audience check.";
  if (((((audience == 4) && (!p.wizard)) || ((audience == 3) && (!p.programmer))) || ((audience == 2) && (!$object_utils:isa(p, $builder)))) || (this:get_log_level_for(p, title) > level))
    players = setremove(players, p);
  endif
endfor
if (players)
  title = $string_utils:uppercase(title);
  for x in (players)
    if (typeof(msg) == LIST)
      (level != this.default_log_level) && x:tell(((("[" + title) + "] ") + level_desc) + ":");
      for m in (msg)
        x:tell((("[" + title) + "] ") + m);
      endfor
    else
      x:tell(((("[" + title) + "] ") + ((level != this.default_log_level) ? level_desc + ": " | "")) + msg);
    endif
  endfor
endif
"Last modified Mon Mar 12 04:15:34 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"match_log_level" this none this xd
@program $logger:match_log_level
":match_log_level(level): Find all matching log levels.";
{level} = args;
matches = {};
if (!level)
  return matches;
endif
for l in (this.log_levels)
  if ((level == l) || (index(l, level) == 1))
    matches = {@matches, l};
  endif
endfor
return matches;
"Last modified Mon Mar 12 04:25:13 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"get_log_audience" this none this xd
@program $logger:get_log_audience
{log} = args;
(!caller_perms().wizard) && raise(E_PERM);
return `this.(log + "_log")[1] ! E_PROPNF => raise(E_INVARG)';
"Last modified Wed Aug  9 15:04:44 2017 CDT by Coderunner Jason Perino (#97@ThetaCore).";
.
@verb $logger:"get_log_level_for" this none this xd
@program $logger:get_log_level_for
":get_log_level_for([who,] log): Get the level of messages that who is listening to.";
{?who = player, log} = args;
(!caller_perms().wizard) && raise(E_PERM);
(!$object_utils:isa(who, $player)) && raise(E_INVARG);
(!$object_utils:has_property(this, log + "_log")) && raise(E_INVARG);
return `who.log_levels[log in $list_utils:slice(who.log_levels)][2] ! E_RANGE => this.default_log_level';
"Last modified Mon Mar 12 04:27:57 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"is_log_readable_by" this none this xd
@program $logger:is_log_readable_by
":is_log_readable_by([who,] log): Get the readability of log by who.";
{?who = player, log} = args;
(!caller_perms().wizard) && raise(E_PERM);
(!$object_utils:isa(who, $player)) && raise(E_INVARG);
(!$object_utils:has_property(this, log + "_log")) && raise(E_INVARG);
audience = this:get_log_audience(log);
return (((audience == 1) || ((audience == 2) && $object_utils:isa(who, $builder))) || ((audience == 3) && who.programmer)) || ((audience == 4) && who.wizard);
"Last modified Mon Mar 12 04:44:52 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"get_log_messages" this none this xd
@program $logger:get_log_messages
":get_log_messages(who, logs[, num-entries[, level]]): Get messages from all matching logs.";
{who, logs, ?entries = 10, ?level = this.default_log_level} = args;
(!caller_perms().wizard) && raise(E_PERM);
(!$object_utils:isa(who, $player)) && raise(E_PERM);
if (!logs)
  logs = this:all_logs(who);
elseif (typeof(logs) == STR)
  logs = {logs};
endif
for l in (logs)
  (!$object_utils:has_property(this, l + "_log")) && raise(E_INVARG);
  (!this:is_log_readable_by(who, l)) && raise(E_INVARG);
endfor
msgs = {};
for l in (logs)
  log_entries = entries;
  found = 0;
  if (this.(l + "_log")[2])
    if (log_entries > length(this.(l + "_log")[2]))
      log_entries = length(this.(l + "_log")[2]);
    endif
    if ((length(logs) == 1) && (level == 1))
      msgs = this.(l + "_log")[2][$ - (log_entries - 1)..$];
    else
      m = length(this.(l + "_log")[2]);
      "Check for messages which are at the specified level or higher.";
      while (m >= 1)
        if (this.(l + "_log")[2][m][2] >= level)
          found = found + 1;
          msgs = {(length(logs) == 1) ? this.(l + "_log")[2][m] | {l, @this.(l + "_log")[2][m]}, @msgs};
          if (found == log_entries)
            break;
          endif
        endif
        m = m - 1;
      endwhile
    endif
  endif
endfor
if (length(logs) > 1)
  msgs = $list_utils:sort(msgs, $list_utils:slice(msgs, 2));
endif
if (length(msgs) > entries)
  msgs = msgs[$ - (entries - 1)..$];
endif
return msgs;
"Last modified Mon Mar 12 04:41:26 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"set_log_level_for" this none this xd
@program $logger:set_log_level_for
":set_log_level_for([who,] log, level): Set the level of messages that who is listening to to level.";
{?who = player, log, level} = args;
(!caller_perms().wizard) && raise(E_PERM);
(!$object_utils:isa(who, $player)) && raise(E_INVARG);
(!$object_utils:has_property(this, log + "_log")) && raise(E_INVARG);
((level < 1) || (level > (length(this.log_levels) + 1))) && raise(E_INVARG);
l = log in $list_utils:slice(who.log_levels);
if (!l)
  who.log_levels = setadd(who.log_levels, {log, level});
else
  who.log_levels[l][2] = level;
endif
"Last modified Mon Mar 12 04:43:35 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $logger:"init_for_core" this none this xd
@program $logger:init_for_core
!caller_perms().wizard && raise(E_PERM);
for p in (properties(this))
  if (p[$ - 3..$] == "_log")
    delete_property(this, p);
  endif
endfor
this.max_log_length = 5000;
this.default_log_audience = 4;
this.default_log_level = 2;
level = `this.log_levels[1] ! ANY => ""';
this.log_levels = {"debug", "info", "notice", "warning", "alert", "error", "critical", "emergency"};
if (level)
  info = verb_info(this, level)[1..2];
  info = {@info, $string_utils:from_list(this.log_levels, " ")};
  set_verb_info(this, level, info);
else
  player:tell("Warning: Couldn't reset log levels on logger.");
endif
"Last modified Mon Mar 12 05:24:58 2018 CDT by Jason Perino (#91@ThetaCore).";
.
"***finished***
