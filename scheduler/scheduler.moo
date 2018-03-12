@create $feature named new scheduler:new scheduler,new,scheduler
@corify scheduler as $scheduler
@prop $scheduler."cron_task" 0 ""
@prop $scheduler."cron_tasks" {} ""
@prop $scheduler."timer_tasks" {} ""
@prop $scheduler."timer_task" 0 ""
@prop $scheduler."special_cron_tasks" {} rc
;;$scheduler.("special_cron_tasks") = {{"hourly", 1520852400, 0, -1, -1, -1, -1, #-1, #-1, "_cron_hourly", {}}, {"daily", 1520830800, 0, 0, -1, -1, -1, #-1, #-1, "_cron_daily", {}}, {"weekly", 1520748000, 0, 0, -1, -1, 0, #-1, #-1, "_cron_weekly", {}}, {"monthly", 1519884000, 0, 0, 1, -1, -1, #-1, #-1, "_cron_monthly", {}}, {"quarterly", 1519884000, 0, 0, 1, -3, -1, #-1, #-1, "_cron_quarterly", {}}, {"semiannually", 1512108000, 0, 0, 1, -6, -1, #-1, #-1, "_cron_semiannually", {}}, {"annually", 1514786400, 0, 0, 1, 1, -1, #-1, #-1, "_cron_annually", {}}}
;;$scheduler.("help_msg") = {"The new scheduler object manages scheduled tasks that are scheduled to execute after a number of seconds (timer tasks), and those that are scheduled to go off one or more times, depending on the minute, hour, day, weekday or month (Cron tasks).", "Cron ranges are stored as integers, or as lists containing a mixture of integers, or sublists of integers specifying a subrange.", "A range of -1 is equivalent to the asterisk (*) character in Cron. A range of -2 or lower is equivalent to \"*/#\" in Cron, so -4 would be equivalent to \"*/4\".", "Negative numbers are only valid if used as the entire range, and not inside a list with other elements.", "Subranges can contain either two or three elements. The start and end of the subrange, and optionally, a skip value for the range.", "For example, a subrange of {3, 12, 3} would run at 3, 6, 9 and 12, and would be equivalent to \"3-12/3\" in Cron.", "", "This object and all related code was originally written by Jason SantaAna-White.", "This  object and other MOO code is available from https://github.com/jasonhsw/MOO-stuff"}
;;$scheduler.("feature_verbs") = {"run", "schedule_timer", "kill_timer", "@timers", "@mktimer", "@rmtimer", "schedule_cron", "kill_cron", "@cron", "@mkcron", "@rmcron"}
;;$scheduler.("aliases") = {"new scheduler", "new", "scheduler"}
;;$scheduler.("description") = "This is the new scheduler object. It manages the scheduling and execution of timer and cron tasks."
;;$scheduler.("object_size") = {61503, 1513702273}
@verb $scheduler:"check_range" this none this xd
@program $scheduler:check_range
":check_range(value, range): check whether value falls within range";
"Where value is an int, and range is a list containing ints or lists consisting of two or three ints.";
"The range -1 acts as a wildcard, so the verb will always return true in this case.";
"Returns: 1 if value falls within range, 0 otherwise.";
{value, range} = args;
if (typeof(range) == INT)
  if (range == -1)
    return 1;
  elseif ((range < -1) && ((value % abs(range)) == 0))
    return 1;
  else
    range = {range};
  endif
endif
for r in (range)
  if ((typeof(r) == INT) && (value == r))
    return 1;
  elseif (typeof(r) == LIST)
    if (((length(r) == 2) && (value >= r[1])) && (value <= r[2]))
      return 1;
    elseif ((length(r) == 3) && (((value >= r[1]) && (value <= r[2])) && (((value - r[1]) % r[3]) == 0)))
      return 1;
    endif
  endif
endfor
"Last modified Thu Aug 31 08:10:21 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"validate_range" this none this xd
@program $scheduler:validate_range
":validate_range(range, min, max): Make sure all elements within range are >= min and <= max.";
"A range of -1 is always considered valid.";
"Returns: 1 if range is valid, 0 otherwise.";
{range, min, max} = args;
if ((typeof(range) != INT) && (typeof(range) != LIST))
  return;
elseif (typeof(range) == INT)
  if (range == -1)
    return 1;
  elseif ((range < -1) && (abs(range) <= (max / 2)))
    return 1;
  else
    range = {range};
  endif
endif
for r in (range)
  if ((typeof(r) != INT) && (typeof(r) != LIST))
    return;
  elseif ((typeof(r) == INT) && ((r < min) || (r > max)))
    return;
  elseif (typeof(r) == LIST)
    if ((length(r) < 2) || (length(r) > 3))
      return;
    elseif (((((((typeof(r[1]) != INT) || (typeof(r[2]) != INT)) || (r[1] < min)) || (r[1] > max)) || (r[2] < min)) || (r[2] > max)) || (r[1] >= r[2]))
      return;
    elseif ((length(r) == 3) && (((typeof(r[3]) != INT) || (r[3] < 2)) || (r[3] > (max / 2))))
      return;
    endif
  endif
endfor
return 1;
"Last modified Tue Sep  5 22:50:44 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"run" this none this
@program $scheduler:run
":run(): Start the scheduler loops.";
(!caller_perms().wizard) && raise(E_PERM);
res = 0;
if (this:cron_loop())
  res = 1;
endif
if (this:timer_loop())
  res = 1;
endif
return res;
"Last modified Fri Sep  8 07:22:16 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"cron_loop" this none this xd
@program $scheduler:cron_loop
":cron_loop(): The core of the Cron scheduler. Once a minute, checks for Cron tasks that need to be run.";
(caller != this) && raise(E_PERM);
if ((!$code_utils:task_valid(this.cron_task)) && (this.special_cron_tasks || this.cron_tasks))
  time = 60 - toint(ctime(time())[18..19]);
  fork task (time)
    while (this.special_cron_tasks || this.cron_tasks)
      this:check_cron_tasks();
      suspend(60 - toint(ctime()[18..19]));
    endwhile
  endfork
  this.cron_task = task;
  return task;
endif
"Last modified Thu Sep 14 08:18:00 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"check_cron_tasks" this none this xd
@program $scheduler:check_cron_tasks
":check_cron_tasks(): Checks if Cron-based tasks need to be executed.";
"";
"This should only be called by the scheduler itself...";
"(caller != this) && raise(E_PERM);";
su = $string_utils;
tu = $time_utils;
now = ctime();
minute = toint(now[15..16]);
hour = toint(now[12..13]);
day = toint(now[9..10]);
month = now[5..7] in tu.monthabbrs;
weekday = (now[1..3] in tu.dayabbrs) - 1;
for tasklist in ({"special_cron_tasks", "cron_tasks"})
  for t in [1..length(this.(tasklist))]
    {task_id, task_last_run, task_minute, task_hour, task_day, task_month, task_weekday, task_owner, object, verb, task_args} = this.(tasklist)[t];
    task_owner = (task_owner == $nothing) ? this.owner | task_owner;
    object = (object == $nothing) ? this | object;
    if ((((this:check_range(minute, task_minute) && this:check_range(hour, task_hour)) && this:check_range(day, task_day)) && this:check_range(month, task_month)) && this:check_range(weekday, task_weekday))
      fork (0)
        try
          set_task_perms(task_owner);
          object:(verb)(@task_args);
        except e (ANY)
          "I use my traceback handler and logger here, but you may want to do something different.";
                    "tb = $tb_handler:format_traceback(e[2], e[4], \"\");";
          "$logger:notice(\"tracebacks\", {(((\"Traceback from \" + su:tn(this)) + \" while firing Cron task ID \") + tostr(task_id)) + \"):\", @tb});";
          raise(e[1]);
        endtry
      endfork
      this.(tasklist)[t][2] = time();
    endif
  endfor
endfor
"Last modified Mon Sep 11 01:57:50 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"get_range_representation" this none this xd
@program $scheduler:get_range_representation
":get_range_representation(range): Get a string representation of range.";
{range} = args;
if (typeof(range) == INT)
  if (range == -1)
    return "*";
  elseif (range < -1)
    return "*/" + tostr(abs(range));
  else
    range = {range};
  endif
endif
rep = "";
for r in [1..length(range)]
  if (typeof(range[r]) == INT)
    rep = rep + tostr(range[r]) + ((r < length(range)) ? "," | "");
  elseif (typeof(range[r]) == LIST)
    rep = rep + (((tostr(range[r][1]) + "-") + tostr(range[r][2])) + ((length(range[r]) == 3) ? "/" + tostr(range[r][3]) | "")) + ((r < length(range)) ? "," | "");
  endif
endfor
return rep;
"Last modified Thu Aug 31 09:10:36 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"parse_range_representation" this none this xd
@program $scheduler:parse_range_representation
":parse_range_representation(representation): Get a range of values from representation.";
"Representation should be a string containing a standard cron range.";
"Returns: range on success, blank list if representation is an invalid range representation.";
{rep} = args;
su = $string_utils;
range = {};
if (rep == "*")
  return -1;
elseif (((length(rep) > 2) && (rep[1..2] == "*/")) && ((n = toint(rep[3..$])) > 1))
  return n - (n * 2);
endif
rep_list = su:explode(rep, ",");
for r in (rep_list)
  if (((i = index(r, "-")) > 1) && (i < length(r)))
    if (((j = index(r, "/")) && (j < length(r))) && (toint(r[j + 1..$]) > 1))
      skip = toint(r[j + 1..$]);
      r = r[1..j - 1];
    else
      skip = 0;
    endif
    if (su:is_integer(r[1..i - 1]) && su:is_integer(r[i + 1..$]))
      min = toint(r[1..i - 1]);
      max = toint(r[i + 1..$]);
      range = {@range, skip ? {min, max, skip} | {min, max}};
    else
      return {};
    endif
  elseif (su:is_integer(r))
    range = {@range, toint(r)};
  else
    return {};
  endif
endfor
return range;
"Last modified Sat Sep  9 20:14:08 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"check_timer_tasks" this none this xd
@program $scheduler:check_timer_tasks
":check_timer_tasks(): Check whether scheduled timer tasks need to be executed.";
"";
"This should only be called by the scheduler itself...";
(caller != this) && raise(E_PERM);
suspend_time = 86400;
t = 1;
while (t <= length(this.timer_tasks))
  {task_id, task_interval, task_schedule_time, task_time, task_owner, object, verb, task_args} = this.timer_tasks[t];
  if (task_time <= time())
    fork (0)
      try
        set_task_perms(task_owner);
        object:(verb)(@task_args);
      except e (ANY)
        "I use my traceback handler and logger here, but you may want to do something different.";
        "tb = $tb_handler:format_traceback(e[2], e[4], \"\");";
        "$logger:notice(\"tracebacks\", {(((\"Traceback from \" + $su:nn(this)) + \" while firing timer task ID \") + tostr(task_id)) + \"):\", @tb});";
        raise(e[1]);
      endtry
    endfork
    if (task_interval)
      task_time = this.timer_tasks[t][4] = (time() + task_interval) - ((time() - task_schedule_time) % task_interval);
    else
      task_time = 0;
      this.timer_tasks = listdelete(this.timer_tasks, t);
      continue;
    endif
  endif
  if (((time = task_time - time()) < suspend_time) && (time > 0))
    suspend_time = task_time - time();
  endif
  t = t + 1;
endwhile
return this.timer_tasks ? suspend_time | 0;
"Last modified Mon Sep 11 01:58:20 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"timer_loop" this none this xd
@program $scheduler:timer_loop
":timer_loop(): The core of the timer task scheduler. Checks for timer tasks that need to be run. Suspends until it is time to run another task.";
(caller != this) && raise(E_PERM);
if ((!$code_utils:task_valid(this.timer_task)) && this.timer_tasks)
  fork task (0)
    while (this.timer_tasks)
      suspend(this:check_timer_tasks());
    endwhile
  endfork
  this.timer_task = task;
  return task;
endif
"Last modified Thu Sep 14 08:19:04 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"schedule_timer schedule_timer_every" this none this 
@program $scheduler:schedule_timer
":schedule_timer(interval, object, \"verb\"[, args[, owner]]): Schedule a timer task to be executed after a specific number of seconds have elapsed.";
"The schedule_timer_every variant will schedule the task to be run indefinitely, every interval seconds.";
(!caller_perms().wizard) && raise(E_PERM);
{interval, object, vrb, ?args = {}, ?owner = caller_perms()} = args;
lu = $list_utils;
ou = $object_utils;
(((((((typeof(interval) != INT) || (interval <= 0)) || (!`$recycler:valid(object) ! ANY => 0')) || (typeof(vrb) != STR)) || (!ou:has_callable_verb(object, vrb))) || (typeof(args) != LIST)) || (!`$recycler:valid(owner) ! ANY => 0')) &&
raise(E_INVARG);
while ((id = random()) in lu:slice(this.timer_tasks))
endwhile
this.timer_tasks = setadd(this.timer_tasks, {id, (verb[$ - 4..$] == "every") ? interval | 0, time(), time() + interval, owner, object, vrb, args});
$code_utils:task_valid(this.timer_task) ? resume(this.timer_task) | this:timer_loop();
return id;
"Last modified Sat Sep  9 20:11:04 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"kill_timer" this none this
@program $scheduler:kill_timer
":kill_timer(id): Kill (remove) a scheduled timer task.";
(!caller_perms().wizard) && raise(E_PERM);
{id} = args;
lu = $list_utils;
(!(t = id in lu:slice(this.timer_tasks))) && raise(E_INVARG);
this.timer_tasks = listdelete(this.timer_tasks, t);
$code_utils:task_valid(this.timer_task) && resume(this.timer_task);
"Last modified Sat Sep  9 20:12:38 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"schedule_cron" this none this
@program $scheduler:schedule_cron
":schedule_cron(minute, hour, day, month, weekday, object, verb[, args[, owner]]): Schedule a Cron task.";
(!caller_perms().wizard) && raise(E_PERM);
{minute, hour, day, month, weekday, object, vrb, ?args = {}, ?owner = caller_perms()} = args;
lu = $list_utils;
ou = $object_utils;
((((((!this:validate_range(minute, 0, 59)) || (!this:validate_range(hour, 0, 23))) || (!this:validate_range(day, 1, 31))) || (!this:validate_range(month, 1, 12))) || (!this:validate_range(weekday, 0, 6))) || (!`is_player(owner) ! ANY => 0')) && raise(E_INVARG);
(((!`$recycler:valid(object) ! ANY => 0') || (typeof(vrb) != STR)) || (!ou:has_callable_verb(object, vrb))) && raise(E_VERBNF);
while ((id = random()) in lu:slice(this.cron_tasks))
endwhile
this.cron_tasks = setadd(this.cron_tasks, {id, 0, minute, hour, day, month, weekday, owner, object, vrb, args});
(!$code_utils:task_valid(this.cron_task)) && this:cron_loop();
return id;
"Last modified Sat Sep  9 20:11:48 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"kill_cron" this none this
@program $scheduler:kill_cron
":kill_cron(id): Kill (remove) a Cron task.";
(!caller_perms().wizard) && raise(E_PERM);
{id} = args;
lu = $list_utils;
(!(t = id in lu:slice(this.cron_tasks))) && raise(E_INVARG);
this.cron_tasks = listdelete(this.cron_tasks, t);
"Last modified Sat Sep  9 20:09:07 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"_cron_hourly" this none this xd
@program $scheduler:_cron_hourly
"_cron_hourly(): Special Cron task that executes at the beginning of every hour.";
"Last modified Thu Sep 14 08:13:48 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"_cron_daily" this none this xd
@program $scheduler:_cron_daily
":_cron_daily(): Special Cron task that executes daily (at midnight.)";
"Last modified Thu Sep 14 08:10:09 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"_cron_weekly" this none this xd
@program $scheduler:_cron_weekly
":_cron_weekly(): Special Cron task that executes at midnight on Sundays.";
"Last modified Thu Sep 14 08:10:16 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"_cron_monthly" this none this xd
@program $scheduler:_cron_monthly
":_cron_monthly(): Special Cron task that executes at midnight on the first of every month.";
"Last modified Thu Sep 14 08:10:23 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"_cron_quarterly" this none this xd
@program $scheduler:_cron_quarterly
":_cron_quarterly(): Special Cron task that executes at midnight on the first of January, April, July and October.";
"Last modified Thu Sep 14 08:10:30 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"_cron_semiannually" this none this xd
@program $scheduler:_cron_semiannually
":_cron_semiannually(): Special Cron task that executes at midnight on the first of January and July.";
"Last modified Thu Sep 14 08:10:37 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"_cron_annually" this none this xd
@program $scheduler:_cron_annually
":_cron_annually(): Special Cron task that executes at midnight on the first of January.";
"Last modified Thu Sep 14 08:10:45 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"look_self" this none this rxd #2
@program $scheduler:look_self
lu = $list_utils;
su = $string_utils;
tu = $time_utils;
pass();
player = callers()[$][5];
ll = `player:linelen() ! ANY => 79';
if (player.wizard && (ll >= 79))
  player:tell("");
  if ((!this.timer_tasks) && (!this.cron_tasks))
    return player:tell("No tasks.");
  endif
  if (this.timer_tasks)
    player:tell(su:center("Scheduled timer tasks:", ll));
    field_length = ((ll < 100) ? ll - 12 | (ll - 14)) / 4;
    content_length = (ll < 100) ? field_length - 2 | (field_length - 4);
    player:tell("");
    player:tell((((su:left("ID", 14) + su:left("Next Run", field_length)) + su:left("Interval", field_length)) + su:left("Owner", field_length)) + su:left("Verb", field_length));
    player:tell(su:space(ll, "-"));
    for t in (lu:sort_alist(this.timer_tasks, 4))
      {task_id, task_interval, task_schedule_time, task_time, task_owner, object, verb, task_args} = t;
      line = su:left(tostr(task_id), (ll < 100) ? 12 | 14) + su:left(tu:dhms(task_time - time())[1..min(content_length, $)], field_length);
      line = line + su:left(task_interval ? tu:dhms(task_interval)[1..min(content_length, $)] | "", field_length);
      line = line + su:left((`task_owner:titlec() ! ANY => task_owner.name' + ((field_length >= 20) ? (" (" + tostr(task_owner)) + ")" | ""))[1..min(content_length, $)], field_length);
      line = line + su:left((((((((field_length >= 20) ? $code_utils:corify_object(object) | tostr(object)) + ":") + verb) + "(") + toliteral(task_args)[2..$ - 1]) + ")")[1..min(field_length, $)], field_length);
      player:tell(line);
    endfor
    player:tell(su:space(ll, "-"));
    player:tell("");
  endif
  if (this.cron_tasks)
    player:tell(su:center("Scheduled Cron tasks:", ll));
    l1_field_length = (ll - ((ll < 100) ? 12 | 14)) / 2;
    l1_content_length = l1_field_length - ((ll < 100) ? 2 | 4);
    l2_field_length = ll / 5;
    l2_content_length = (ll < 100) ? l2_field_length - 2 | (l2_field_length - 4);
    player:tell("");
    player:tell((su:left("ID", 14) + su:left("Last Run", l1_field_length)) + su:left("Owner", l1_field_length));
    player:tell((((su:left("Minute", l2_field_length) + su:left("Hour", l2_field_length)) + su:left("Day", l2_field_length)) + su:left("Month", l2_field_length)) + su:left("Weekday", l2_field_length));
    player:tell(su:left("Verb", ll));
    player:tell(su:space(ll, "-"));
    for ct in (this.cron_tasks)
      {task_id, task_last_run, task_minute, task_hour, task_day, task_month, task_weekday, task_owner, object, verb, task_args} = ct;
      player:tell((su:left(tostr(task_id), 14) + su:left(task_last_run ? tu:dhms(time() - task_last_run)[1..min(l1_content_length, $)] | "", l1_field_length)) + su:left((((`task_owner:titlec() ! ANY => task_owner.name' + " (") +
tostr(task_owner)) + ")")[1..min(l1_field_length, $)], l1_field_length));
      line = su:left(this:get_range_representation(task_minute)[1..min(l2_content_length, $)], l2_field_length) + su:left(this:get_range_representation(task_hour)[1..min(l2_content_length, $)], l2_field_length);
      line = line + su:left(this:get_range_representation(task_day)[1..min(l2_content_length, $)], l2_field_length) + su:left(this:get_range_representation(task_month)[1..min(l2_content_length, $)], l2_field_length);
      line = line + su:left(this:get_range_representation(task_weekday)[1..min(l2_field_length, $)], l2_field_length);
      player:tell(line);
      player:tell(su:left(((((($code_utils:corify_object(object) + ":") + verb) + "(") + toliteral(task_args)[2..$ - 1]) + ")")[1..min(ll, $)], ll));
      player:tell("");
    endfor
    player:tell(su:space(ll, "-"));
  endif
endif
"Last modified Mon Sep 11 09:14:22 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"@timers" any none none rxd
@program $scheduler:@timers
"Usage: @timers";
"@timers <spec1>[,<spec2>[,...]]]";
"Check timer task scheduler status.";
"You may search the scheduler by task ID, by verb reference, or by player name.";
"Simultaneous queries are possible by separating the queries with a comma (,)";
lu = $list_utils;
su = $string_utils;
player = callers()[$][5];
if (!player.wizard)
  return player:tell("No.");
endif
if (!argstr)
  ll = `player:linelen() ! ANY => 79';
  tasks = length(this.timer_tasks);
  player:tell(su:space(ll, "-"));
  player:tell(su:center(("It is now " + ctime()[5..$]) + ".", ll));
  player:tell(su:center("The timer task scheduler is " + ($code_utils:task_valid(this.timer_task) ? "active." | "inactive."), ll));
  player:tell(su:center(((("There " + ((tasks == 1) ? "is " | "are ")) + ((!tasks) ? "no" | tostr(tasks))) + " timer ") + ((tasks == 1) ? "task." | "tasks."), ll));
  player:tell(su:space(ll, "-"));
  tasklist = lu:slice(this.timer_tasks);
else
  tasklist = this:search_timer_tasks(argstr);
endif
if (!tasklist)
  argstr && player:tell("No timer tasks matched your query.");
else
  for t in (tasklist)
    info = this:get_timer_display(t);
    if (!info)
      player:tell(("Timer task " + tostr(t)) + " doesn't exist.");
    else
      player:tell_lines(info);
    endif
  endfor
endif
"Last modified Sat Sep  9 20:16:06 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"@add-timer @mktimer" any any any rxd
@program $scheduler:@add-timer
"Usage: @add-timer <object>:<verb>[(<args>)][ [in|every] <interval>]";
"Schedule a timer task.";
cu = $command_utils;
su = $string_utils;
lu = $list_utils;
tu = $time_utils;
player = callers()[$][5];
if (!player.wizard)
  player:tell("No.");
endif
if (!argstr)
  return player:tell(("Usage: " + verb) + " <object>:<verb>[(<args>)][ [in|every] <interval>]");
endif
intstr = "";
interval = 0;
preps = {" in ", " every "};
for type in [1..length(preps)]
  if (i = index(argstr, preps[type]))
    interval = tu:parse_english_time_interval(intstr = argstr[i + length(preps[type])..$]);
    argstr = argstr[1..i - 1];
    break;
  endif
endfor
if (!interval)
  return player:tell(intstr ? "Invalid time interval." | "Time interval expected.");
endif
vargs = {};
if (((argstr[$] == ")") && (i = index(argstr, "("))) && (i < (length(argstr) - 1)))
  vargstr = argstr[i + 1..$ - 1];
  argstr = argstr[1..i - 1];
  vargs = eval(("return {" + vargstr) + "};");
  if (!vargs[1])
    return player:tell("Invalid verb arguments.");
  else
    vargs = vargs[2];
  endif
endif
if (!argstr)
  return player:tell("<object>:<verb> expected.");
elseif (!(vr = $code_utils:parse_verbref(argstr)))
  return player:tell("Invalid verb reference.");
elseif (cu:object_match_failed(object = player:my_match_object(vr[1]), vr[1]))
  return;
elseif (!$object_utils:has_callable_verb(object, vr[2]))
  return player:tell((($code_utils:corify_object(object) + ":") + vr[2]) + " doesn't exist, or is uncallable.");
else
  vrb = vr[2];
endif
id = this:((type == 1) ? "schedule_timer" | "schedule_timer_every")(interval, object, vrb, vargs, player);
player:tell(("Task " + tostr(id)) + " scheduled.");
"Last modified Sat Sep  9 16:54:39 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"@kill-timer @rmtimer" any none none rxd
@program $scheduler:@kill-timer
"Usage: @kill-timer <spec1>[,<spec2>[,...]]]";
"@kill-timer all";
"Kill one or more timer tasks.";
su = $string_utils;
lu = $list_utils;
player = callers()[$][5];
if (!player.wizard)
  player:tell("No.");
endif
if (!argstr)
  player:tell(("Usage: " + verb) + " <spec1>[,<spec2>[,...]]]");
  return player:tell(("Or " + verb) + " all");
elseif (argstr == "all")
  tasklist = lu:slice(this.timer_tasks);
else
  tasklist = this:search_timer_tasks(argstr);
endif
if (!tasklist)
  argstr && player:tell((argstr != "all") ? "No timer tasks matched your query." | "There are no timer tasks.");
else
  for t in (tasklist)
    if (!`this:kill_timer(t) ! E_INVARG')
      player:tell(("Timer task " + tostr(t)) + " killed.");
    else
      player:tell(("Timer task " + tostr(t)) + " doesn't exist.");
    endif
  endfor
endif
"Last modified Mon Sep 11 09:39:15 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"@cron" any none none rxd
@program $scheduler:@cron
"Usage: @cron";
"@cron <spec1>[,<spec2>[,...]]]";
"Check Cron task scheduler status.";
"You may search the scheduler by task ID, by verb reference, or by player name.";
"Simultaneous queries are possible by separating the queries with a comma (,)";
lu = $list_utils;
su = $string_utils;
player = callers()[$][5];
if (!player.wizard)
  return player:tell("No.");
endif
if (!argstr)
  ll = `player:linelen() ! ANY => 79';
  tasks = length(this.cron_tasks);
  player:tell(su:space(ll, "-"));
  player:tell(su:center(("It is now " + ctime()[5..$]) + ".", ll));
  player:tell(su:center("The Cron task scheduler is " + ($code_utils:task_valid(this.cron_task) ? "active." | "inactive."), ll));
  player:tell(su:center(((("There " + ((tasks == 1) ? "is " | "are ")) + ((!tasks) ? "no" | tostr(tasks))) + " Cron ") + ((tasks == 1) ? "task." | "tasks."), ll));
  player:tell(su:space(ll, "-"));
  tasklist = lu:slice(this.cron_tasks);
else
  tasklist = this:search_cron_tasks(argstr);
endif
if (!tasklist)
  argstr && player:tell("No Cron tasks matched your query.");
else
  for t in (tasklist)
    info = this:get_cron_display(t);
    if (!info)
      player:tell(("Cron task " + tostr(t)) + " doesn't exist.");
    else
      player:tell_lines(info);
    endif
  endfor
endif
"Last modified Sat Sep  9 20:16:33 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"@add-cron @mkcron" any any any rxd
@program $scheduler:@add-cron
"Usage: @mkcron  <minute> <hour> <day> <month> <weekday> <object>:<verb>[(<args>)]";
cu = $command_utils;
su = $string_utils;
player = callers()[$][5];
if (!player.wizard)
  return player:tell("No.");
endif
if (!argstr)
  return player:tell(("Usage: " + verb) + " <minute> <hour> <day> <month> <weekday> <object>:<verb>[(<args>)]");
endif
vargs = {};
if (((argstr[$] == ")") && (i = index(argstr, "("))) && (i < (length(argstr) - 1)))
  vargstr = argstr[i + 1..$ - 1];
  argstr = argstr[1..i - 1];
  vargs = eval(("return {" + vargstr) + "};");
  if (!vargs[1])
    return player:tell("Invalid verb arguments.");
  else
    vargs = vargs[2];
  endif
endif
when = su:explode(argstr, " ");
if ((!when) || (length(when) != 6))
  return player:tell("<minute> <hour> <day> <month> <weekday> <object>:<verb> expected.");
endif
refstr = when[6];
if (!(vr = $code_utils:parse_verbref(refstr)))
  return player:tell("Invalid verb reference.");
elseif (cu:object_match_failed(object = player:my_match_object(vr[1]), vr[1]))
  return;
elseif (!$object_utils:has_callable_verb(object, vr[2]))
  return player:tell((($code_utils:corify_object(object) + ":") + vr[2]) + " doesn't exist, or is uncallable.");
else
  vrb = vr[2];
endif
if ((!(minute = this:parse_range_representation(when[1]))) || (!this:validate_range(minute, 0, 59)))
  return player:tell("Invalid minute spec.");
elseif ((!(hour = this:parse_range_representation(when[2]))) || (!this:validate_range(hour, 0, 23)))
  return player:tell("Invalid hour spec.");
elseif ((!(day = this:parse_range_representation(when[3]))) || (!this:validate_range(day, 1, 31)))
  return player:tell("Invalid day spec.");
elseif ((!(month = this:parse_range_representation(when[4]))) || (!this:validate_range(month, 1, 12)))
  return player:tell("Invalid month spec.");
elseif ((!(weekday = this:parse_range_representation(when[5]))) || (!this:validate_range(weekday, 0, 6)))
  return player:tell("Invalid weekday spec.");
endif
id = this:schedule_cron(minute, hour, day, month, weekday, object, vrb, vargs, player);
player:tell(("Cron task " + tostr(id)) + " scheduled.");
"Last modified Sat Sep  9 21:27:01 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"@kill-cron @rmcron" any none none rxd
@program $scheduler:@kill-cron
"Usage: @kill-Cron <spec1>[,<spec2>[,...]]]";
"@kill-Cron all";
"Kill one or more Cron tasks.";
su = $string_utils;
lu = $list_utils;
player = callers()[$][5];
if (!player.wizard)
  player:tell("No.");
endif
if (!argstr)
  player:tell(("Usage: " + verb) + " <spec1>[,<spec2>[,...]]]");
  return player:tell(("Or " + verb) + " all");
elseif (argstr == "all")
  tasklist = lu:slice(this.cron_tasks);
else
  tasklist = this:search_cron_tasks(argstr);
endif
if (!tasklist)
  argstr && player:tell((argstr != "all") ? "No Cron tasks matched your query." | "There are no Cron tasks.");
else
  for t in (tasklist)
    if (!`this:kill_cron(t) ! E_INVARG')
      player:tell(("Cron task " + tostr(t)) + " killed.");
    else
      player:tell(("Cron task " + tostr(t)) + " doesn't exist.");
    endif
  endfor
endif
"Last modified Mon Sep 11 09:38:15 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"get_timer_display" this none this xd
@program $scheduler:get_timer_display
":get_timer_display(id): Returns a list of informational strings about the specified timer task.";
{id} = args;
(!caller_perms().wizard) && raise(E_PERM);
su = $string_utils;
lu = $list_utils;
tu = $time_utils;
if (!(t = id in lu:slice(this.timer_tasks)))
  return {};
else
  {task_id, task_interval, task_schedule_time, task_time, task_owner, object, verb, task_args} = this.timer_tasks[t];
  ll = `player:linelen() ! ANY => 79';
  field_length = ll / 2;
  content_length = (ll < 100) ? field_length - 2 | (field_length - 4);
  info = {su:left("ID: " + tostr(task_id), field_length) + su:left((((("Owner: " + `task_owner:titlec() ! ANY => owner.name') + " (") + tostr(task_owner)) + ")")[1..min(field_length, $)], field_length)};
  info = {@info, su:left(("Next run: " + tu:dhms(task_time - time()))[1..min(content_length, $)], field_length) + su:left(task_interval ? ("Interval: " + tu:dhms(task_interval))[1..min(field_length, $)] | "", field_length)};
  info = {@info, su:left((((((("Verb: " + $code_utils:corify_object(object)) + ":") + verb) + "(") + toliteral(task_args)[2..$ - 1]) + ")")[1..min(ll, $)], ll), ""};
  return info;
endif
"Last modified Thu Sep 14 08:20:53 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"get_cron_display" this none this xd
@program $scheduler:get_cron_display
":get_cron_display(id): Returns a list of informational strings about the specified Cron task.";
{id} = args;
(!caller_perms().wizard) && raise(E_PERM);
su = $string_utils;
lu = $list_utils;
tu = $time_utils;
if (!(t = id in lu:slice(this.cron_tasks)))
  return {};
else
  {task_id, task_last_run, task_minute, task_hour, task_day, task_month, task_weekday, task_owner, object, verb, task_args} = this.cron_tasks[t];
  ll = `player:linelen() ! ANY => 79';
  field_length = ll / 2;
  content_length = (ll < 100) ? field_length - 2 | (field_length - 4);
  info = {su:left("ID: " + tostr(task_id), field_length) + su:left((((("Owner: " + `task_owner:titlec() ! ANY => owner.name') + " (") + tostr(task_owner)) + ")")[1..min(field_length, $)], field_length)};
  info = {@info, su:center(task_last_run ? ("Last run: " + tu:dhms(time() - task_last_run)) + " ago" | "Never run before", ll), su:center("When:", ll)};
  field_length = ll / 5;
  content_length = (ll < 100) ? field_length - 2 | (field_length - 4);
  info = {@info, (((su:left("Minute", field_length) + su:left("Hour", field_length)) + su:left("Day", field_length)) + su:left("Month", field_length)) + su:left("Weekday", field_length)};
  line = su:left(this:get_range_representation(task_minute)[1..min(content_length, $)], field_length) + su:left(this:get_range_representation(task_hour)[1..min(content_length, $)], field_length);
  line = line + su:left(this:get_range_representation(task_day)[1..min(content_length, $)], field_length) + su:left(this:get_range_representation(task_month)[1..min(content_length, $)], field_length);
  line = line + su:left(this:get_range_representation(task_weekday)[1..min(field_length, $)], field_length);
  info = {@info, line};
  info = {@info, su:left((((((("Verb: " + $code_utils:corify_object(object)) + ":") + verb) + "(") + toliteral(task_args)[2..$ - 1]) + ")")[1..min(ll, $)], ll), ""};
  return info;
endif
"Last modified Thu Sep 14 08:21:15 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"search_timer_tasks" this none this xd
@program $scheduler:search_timer_tasks
":search_timer_tasks(what): Searches the scheduled timer tasks for tasks matching the query.";
"Query may be a task ID, the trailing digits of a task ID (prepended with a percent character (%)), an <object>:<verb> reference, or a player name.";
"Multiple queries may be included by separating each with a comma (,).";
{what} = args;
(!caller_perms().wizard) && raise(E_PERM);
cu = $command_utils;
su = $string_utils;
tasklist = {};
for s in (su:explode(what, ","))
  if (su:is_integer(s))
    tasklist = setadd(tasklist, toint(s));
  elseif ((s[1] == "%") && su:is_integer(`s[2..$] ! E_RANGE => ""'))
    for t in (this.timer_tasks)
      if (tostr(t[1])[$ - (length(s) - 2)..$] == s[2..$])
        tasklist = setadd(tasklist, t[1]);
      endif
    endfor
  elseif (index(s, ":"))
    vr = $code_utils:parse_verbref(s);
    if (!vr)
      return player:tell(("Invalid verb reference: \"" + what) + "\"");
    elseif (cu:object_match_failed(object = player:my_match_object(vr[1]), vr[1]))
      continue;
    else
      for t in (this.timer_tasks)
        if (t[6..7] == {object, vr[2]})
          tasklist = setadd(tasklist, t[1]);
        endif
      endfor
    endif
  else
    if (cu:player_match_failed(plr = su:match_player(s), s))
      continue;
    endif
    for t in (this.timer_tasks)
      if (t[5] == plr)
        tasklist = setadd(tasklist, t[1]);
      endif
    endfor
  endif
endfor
return tasklist;
"Last modified Thu Sep 14 08:25:18 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"search_cron_tasks" this none this xd
@program $scheduler:search_cron_tasks
":search_cron_tasks(what): Searches the scheduled Cron tasks for tasks matching the query.";
"Query may be a task ID, the trailing digits of a task ID (prepended with a percent character (%)), an <object>:<verb> reference, or a player name.";
"Multiple queries may be included by separating each with a comma (,).";
{what} = args;
(!caller_perms().wizard) && raise(E_PERM);
cu = $command_utils;
su = $string_utils;
tasklist = {};
for s in (su:explode(what, ","))
  if (su:is_integer(s))
    tasklist = setadd(tasklist, toint(s));
  elseif ((s[1] == "%") && su:is_integer(`s[2..$] ! E_RANGE => ""'))
    for t in (this.cron_tasks)
      if (tostr(t[1])[$ - (length(s) - 2)..$] == s[2..$])
        tasklist = setadd(tasklist, t[1]);
      endif
    endfor
  elseif (index(s, ":"))
    vr = $code_utils:parse_verbref(s);
    if (!vr)
      return player:tell(("Invalid verb reference: \"" + what) + "\"");
    elseif (cu:object_match_failed(object = player:my_match_object(vr[1]), vr[1]))
      continue;
    else
      for t in (this.cron_tasks)
        if (t[9..10] == {object, vr[2]})
          tasklist = setadd(tasklist, t[1]);
        endif
      endfor
    endif
  else
    if (cu:player_match_failed(plr = su:match_player(s), s))
      continue;
    endif
    for t in (this.cron_tasks)
      if (t[8] == plr)
        tasklist = setadd(tasklist, t[1]);
      endif
    endfor
  endif
endfor
return tasklist;
"Last modified Thu Sep 14 08:24:42 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"server_started" this none this xd
@program $scheduler:server_started
(caller != #0) && raise(E_PERM);
$code_utils:task_valid(this.cron_task) && resume(this.cron_task);
$code_utils:task_valid(this.timer_task) && resume(this.timer_task);
"Last modified Mon Sep 11 02:36:33 2017 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"init_for_core" this none this xd
@program $scheduler:init_for_core
!caller_perms().wizard && raise(E_PERM);
this.cron_tasks = this.special_cron_tasks = this.timer_tasks = {};
special_cron_tasks = {{"hourly", 0, 0, -1, -1, -1, -1, #-1, #-1, "_cron_hourly", {}}, {"daily", 0, 0, 0, -1, -1, -1, #-1, #-1, "_cron_daily", {}}, {"weekly", 0, 0, 0, -1, -1, 0, #-1, #-1, "_cron_weekly", {}}, {"monthly", 0, 0, 0, 1, -1, -1,#-1, #-1, "_cron_monthly", {}}, {"quarterly", 0, 0, 0, 1, -3, -1, #-1, #-1, "_cron_quarterly", {}}, {"semiannually", 0, 0, 0, 1, -6, -1, #-1, #-1, "_cron_semiannually", {}}, {"annually", 0, 0, 0, 1, 1, -1, #-1, #-1, "_cron_annually", {}}};
for s in (special_cron_tasks)
  if ($object_utils:has_callable_verb(this, s[10]))
    this.special_cron_tasks = {@this.special_cron_tasks, s[10]};
    set_verb_code(this, s[10], $code_utils:verb_documentation(this, s[10]));
  endif
endfor
"Last modified Mon Mar 12 08:15:02 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $scheduler:"feature_ok" this none this xd
@program $scheduler:feature_ok
{who} = args;
return who.wizard;
"Last modified Mon Mar 12 08:29:11 2018 CDT by Jason Perino (#91@ThetaCore).";
.
"***finished***