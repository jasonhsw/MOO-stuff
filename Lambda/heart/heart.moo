@create $feature named the heart:the,heart
@corify heart as $heart
@prop $heart."highest_queue" 0 ""
@prop $heart."hearts_per_queue" 25 ""
@prop $heart."beat_interval" 30 ""
@prop $heart."area_beat_interval" 2 ""
@prop $heart."beat_count" 0 ""
@prop $heart."task" 0 ""
@prop $heart."highest_area_queue" 0 ""
@prop $heart."heartbeat_tasks" {} ""
@prop $heart."area_heartbeat_tasks" {} ""
@prop $heart."skip_threshold" 70.0 ""
@prop $heart."last_beat" 0 ""
@prop $heart."last_area_beat" 0 ""
@prop $heart."beats_paused" 0 ""
@prop $heart."area_beats_paused" 0 ""
@prop $heart."report_heartbeat_suspends" 1 ""
@prop $heart."beat_log" {} ""
@prop $heart."area_beat_log" {} ""
@prop $heart."logging_beat" 0 ""
@prop $heart."logging_area_beat" 0 ""
@prop $heart."queue_interval" 0.125 ""
@prop $heart."beats" 0 ""
@prop $heart."area_beats" 0 ""
@prop $heart."beat_msg" "" ""
@prop $heart."area_beat_msg" "" ""
;;$heart.("help_msg") = {"The heart manages the execution of heartbeat tasks on registered objects.", "It separates queues for normal objects from area objects ($area).", "The heart splits the registrations up into queues of no more than .hearts_per_queue entries.", "It does this so it can delay the execution of later tasks slightly, to avoid causing lag.", "When an object registers itself with the heart, it searches the appropriate queues for an available queue.  If all queues are full, a new queue is automatically created.", "The queue properties are of the form \"queue_X\" for normal queues, and \"area_queue_X\" for area queues, where X is the number of the queue.", "", "When an object is registered with the heart, its .heart_queue property is set to the number of the queue that it was placed in.", "When an object is unregistered, its .heart_queue property is set back to 0.", "", "Execution:", "", "If .beats_paused is set to 1, the heart will not execute heartbeat tasks for regular objects and rooms. If .area_beats_paused is set to 1, the heart will not run heartbeat tasks on areas.", "Every .beat_interval seconds, the heart begins running the queues, making sure that the queues execute .queue_interval seconds apart.", "At the same time, it checks to see if .area_beat_interval beats have gone by. IF so, it schedules the area queues to be run in .beat_interval/2 seconds.", "If the heartbeat verb on an object is owned by a programmer, the heart calls set_task_perms() before calling the verb.", "", "Beat skipping", "", "The queue tasks register themselves on .heartbeat_tasks and .area_heartbeat_tasks when they begin running heartbeats on a queue, and remove themselves when finished.", "If more than .skip_threshold percent of these tasks are still running at the time of the next beat, the heart will skip a beat to give these tasks more time to finish.", "", "If the .beat_msg or .area_beat_msg properties are set, the messages will be printed to the room that the heart is in when appropriate, with substitutions. The string \"%b\" will be substituted with the number of objects whose heartbeat verbs were successfully run.", "", "This object and all related code was originally written by Jason SantaAna-White.", "This  object and other MOO code is available from https://github.com/jasonhsw/MOO-stuff"}
;;$heart.("feature_verbs") = {"@log-beat", "@beat-log", "run", "register", "unregister", "register_area", "unregister_area"}
;;$heart.("aliases") = {"the", "heart"}
;;$heart.("description") = "It runs heartbeat tasks on registered objects."
;;$heart.("object_size") = {37166, 1521210644}
@verb $heart:"run" this none this
@program $heart:run
":run() - Start the heart running.";
(!caller_perms().wizard) && raise(E_PERM);
if (!$code_utils:task_valid(this.task))
  "The heart is dead -- start it up.";
  fork task (0)
    this.beat_count = this.area_beat_interval - 1;
    this:beat_task();
  endfork
  this.task = task;
  return task;
endif
"Last modified Fri Mar 16 10:03:49 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"beat_task" this none this xd
@program $heart:beat_task
":beat_task() - The core task of the heart. Schedules beats periodically.";
(!caller_perms().wizard) && raise(E_PERM);
while (1)
  this:beat();
  suspend(this.beat_interval);
endwhile
"Last modified Fri Mar 16 09:44:01 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"beat" this none this xd
@program $heart:beat
":beat() - Schedules queues for execution, schedules an area beat if appropriate.";
(!caller_perms().wizard) && raise(E_PERM);
if ((this.highest_queue > 0) && (!this:skip_beat()))
  if (!this.beats_paused)
    this.last_beat = time();
    if (this.logging_beat == 1)
      this.beat_log = {};
      this.logging_beat = 2;
      $logger:debug("heart", "Beat starting.");
    elseif (this.logging_beat == 2)
      this.logging_beat = 0;
      $logger:debug("heart", "Beat finished.");
    endif
    if (this.beat_msg)
      `this.location:announce_all($string_utils:pronoun_sub($string_utils:substitute(this.beat_msg, {{"%b", tostr(this.beats)}}))) ! ANY';
    endif
    this.beats = 0;
    "Begin scheduling queues.";
    for q in [1..this.highest_queue]
      prop = "queue_" + tostr(q);
      interval = this.queue_interval * tofloat(q);
      if (`this.(prop) ! ANY => 0')
        fork (interval)
          this:run_queue(q);
        endfork
      endif
    endfor
  else
    $logger:notice("heart", "Beats paused.");
  endif
endif
if ((this.beat_count + 1) >= this.area_beat_interval)
  "Time to schedule an area beat.";
  this.beat_count = 0;
  fork (this.beat_interval / 2)
    this:area_beat();
  endfork
else
  this.beat_count = this.beat_count + 1;
endif
"Last modified Fri Mar 16 11:33:25 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"area_beat" this none this xd
@program $heart:area_beat
":area_beat() - Schedules area queues for execution.";
(!caller_perms().wizard) && raise(E_PERM);
if ((this.highest_area_queue > 0) && (!this:skip_area_beat()))
  if (!this.area_beats_paused)
    this.last_area_beat = time();
    if (this.logging_area_beat == 1)
      this.area_beat_log = {};
      this.logging_area_beat = 2;
      $logger:debug("heart", "Area beat starting.");
    elseif (this.logging_area_beat == 2)
      this.logging_area_beat = 0;
      $logger:debug("heart", "Area beat finished.");
    endif
    if (this.area_beat_msg)
      `this.location:announce_all($string_utils:pronoun_sub($string_utils:substitute(this.area_beat_msg, {{"%b", tostr(this.beats)}}))) ! ANY';
    endif
    this.area_beats = 0;
    "Begin scheduling queues.";
    for q in [1..this.highest_area_queue]
      prop = "area_queue_" + tostr(q);
      interval = this.queue_interval * tofloat(q);
      if (`this.(prop) ! ANY => 0')
        fork (interval)
          this:run_area_queue(q);
        endfork
      endif
    endfor
  else
    $logger:notice("heart", "Area beats paused.");
  endif
endif
"Last modified Fri Mar 16 11:33:49 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"run_queue" this none this xd
@program $heart:run_queue
":run_queue(queue) - Run the heartbeat tasks on the objects in queue.";
{queue} = args;
(!caller_perms().wizard) && raise(E_PERM);
"Try to figure out the number of ticks a verb starts with.";
start_ticks = $math_utils:round(ticks_left(), 10000);
prop = "queue_" + tostr(queue);
if ((this.highest_queue >= queue) && (typeof(`this.(prop) ! ANY => 0') == LIST))
  this.heartbeat_tasks = setadd(this.heartbeat_tasks, task_id());
  this:validate_queue(queue);
  queue_log = {};
  for h in (this.(prop))
    suspended = success = 0;
    start = ticks_left();
    try
      this:run_heartbeat(h);
      `h.last_heartbeat_time = time() ! ANY';
      success = 1;
      this.beats = this.beats + 1;
    except (E_NONE)
      "Heartbeat aborted.";
      success = -1;
    except e (ANY)
      this:report_broken_heartbeat(h, e);
    endtry
    elapsed = start - (remaining = ticks_left());
    if ((ticks_left() <= 5000) || (seconds_left() <= 1))
      suspend(0);
      suspended = 1;
    endif
    if (elapsed <= 0)
      "Heartbeat had to suspend() during execution, so try to guess how many ticks it used.";
      "This may not be very accurate, but hopefully it's accurate enough.";
      elapsed = (start_ticks - 2500) + (start_ticks - remaining);
      if (this.report_heartbeat_suspends)
        suspended = 1;
      endif
    endif
    queue_log = {@queue_log, {h, success, suspended, elapsed}};
    if (suspended)
      fork (0)
        this:report_suspension(queue_log, queue);
      endfork
    endif
  endfor
  if (this.logging_beat == 2)
    "We're logging this beat, so save the queue log.";
    this.beat_log = {@this.beat_log, {queue, queue_log}};
  endif
  this.heartbeat_tasks = setremove(this.heartbeat_tasks, task_id());
endif
"Last modified Fri Mar 16 11:09:27 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"run_area_queue" this none this xd
@program $heart:run_area_queue
":run_area_queue(queue) - Run the heartbeat tasks on the objects in queue.";
{queue} = args;
(!caller_perms().wizard) && raise(E_PERM);
"Try to figure out the number of ticks a verb starts with.";
start_ticks = $math_utils:round(ticks_left(), 10000);
prop = "area_queue_" + tostr(queue);
if ((this.highest_area_queue >= queue) && (typeof(`this.(prop) ! ANY => 0') == LIST))
  this.area_heartbeat_tasks = setadd(this.area_heartbeat_tasks, task_id());
  this:validate_queue(queue, 1);
  queue_log = {};
  for h in (this.(prop))
    suspended = success = 0;
    start = ticks_left();
    try
      this:run_heartbeat(h);
      `h.last_heartbeat_time = time() ! ANY';
      success = 1;
      this.area_beats = this.area_beats + 1;
    except (E_NONE)
      "Heartbeat aborted.";
      success = -1;
    except e (ANY)
      this:report_broken_heartbeat(h, e);
    endtry
    elapsed = start - ticks_left();
    if ((ticks_left() <= 5000) || (seconds_left() <= 1))
      suspend(0);
      suspended = 1;
    endif
    if (elapsed <= 0)
      "Heartbeat had to suspend() during execution, so try to guess how many ticks it used.";
      "This may not be very accurate, but hopefully it's accurate enough.";
      elapsed = (start_ticks - 2500) + (start_ticks - remaining);
      if (this.report_heartbeat_suspends)
        suspended = 1;
      endif
    endif
    queue_log = {@queue_log, {h, success, suspended, elapsed}};
    if (suspended)
      fork (0)
        this:report_suspension(queue_log, queue, 1);
      endfork
    endif
  endfor
  if (this.logging_area_beat == 2)
    "We're logging this beat, so save the queue log.";
    this.area_beat_log = {@this.area_beat_log, {queue, queue_log}};
  endif
  this.area_heartbeat_tasks = setremove(this.area_heartbeat_tasks, task_id());
endif
"Last modified Fri Mar 16 11:09:42 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"run_heartbeat" this none this xd
@program $heart:run_heartbeat
":run_heartbeat(object) - Drop privileges if the heartbeat verb is owned by a programmer, and run the verb.";
{what} = args;
(caller != this) && raise(E_PERM);
player = what;
if ((owner = this:heartbeat_owner(what)) != $nothing)
  (owner.programmer && (!owner.wizard)) && set_task_perms(owner);
  what:heartbeat();
endif
"Last modified Fri Mar 16 09:46:57 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"register" this none this
@program $heart:register
":register(object) - Register object with the heart.";
{what} = args;
if ((!$recycler:valid(what)) || isa(what, $area))
  raise(E_INVARG);
elseif (!$object_utils:has_callable_verb(what, "heartbeat"))
  raise(E_INVARG);
elseif (what.heart_queue < 0)
  raise(E_INVARG);
elseif ((what.heart_queue > 0) && (what in `this.("queue_" + tostr(what.heart_queue)) ! ANY => {}'))
  raise(E_INVARG);
else
  "Find a free queue.";
  q = this.highest_queue;
  while (q > 0)
    prop = "queue_" + tostr(q);
    if (length(this.(prop)) < this.hearts_per_queue)
      what.heart_queue = q;
      this.(prop) = setadd(this.(prop), what);
      return q;
    endif
    q = q - 1;
  endwhile
  "No queues free -- create a new one.";
  q = this.highest_queue = this.highest_queue + 1;
  $logger:debug("heart", "adding queue " + tostr(q));
  add_property(this, "queue_" + tostr(q), {what}, {this.owner, ""});
  what.heart_queue = q;
  return q;
endif
"Last modified Fri Mar 16 10:53:18 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"register_area" this none this
@program $heart:register_area
":register_area(area) - Register area with the heart.";
{what} = args;
if ((!$recycler:valid(what)) || (!isa(what, $area)))
  raise(E_INVARG);
elseif (!$object_utils:has_callable_verb(what, "heartbeat"))
  raise(E_INVARG);
elseif (what.heart_queue < 0)
  raise(E_INVARG);
elseif ((what.heart_queue > 0) && (what in `this.("area_queue_" + tostr(what.heart_queue)) ! ANY => {}'))
  raise(E_INVARG);
else
  "Find a free queue.";
  q = this.highest_area_queue;
  while (q > 0)
    prop = "area_queue_" + tostr(q);
    if (length(this.(prop)) < this.hearts_per_queue)
      what.heart_queue = q;
      this.(prop) = setadd(this.(prop), what);
      return q;
    endif
    q = q - 1;
  endwhile
  "No queues free -- create a new one.";
  q = this.highest_area_queue = this.highest_area_queue + 1;
  $logger:debug("heart", "adding area queue " + tostr(q));
  add_property(this, "area_queue_" + tostr(q), {what}, {this.owner, ""});
  what.heart_queue = q;
  return q;
endif
"Last modified Fri Mar 16 10:55:08 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"unregister" this none this
@program $heart:unregister
":unregister(object) - Remove (unregister) object from the appropriate queue on the heart.";
{what} = args;
if (!(queue = `what.heart_queue ! E_PROPNF'))
else
  prop = "queue_" + tostr(queue);
  if ((!$object_utils:has_property(this, prop)) && (queue != -1))
    $logger:notice("heart", (($string_utils:nn(what) + " called unregister with queue=") + tostr(queue)) + ", but no such queue exists.");
  elseif (!(what in this.(prop)))
    $logger:notice("heart", (($string_utils:nn(what) + " called unregister with queue=") + tostr(queue)) + ", but isn't in that queue.");
  else
    this.(prop) = setremove(this.(prop), what);
    what.heart_queue = 0;
  endif
endif
"Last modified Fri Mar 16 09:51:01 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"unregister_area" this none this
@program $heart:unregister_area
":unregister_area(area) - Unregister (remove) area from the appropriate queue on the heart.";
{what} = args;
if (!(queue = `what.heart_queue ! E_PROPNF'))
else
  prop = "area_queue_" + tostr(queue);
  if ((!$object_utils:has_property(this, prop)) && (queue != -1))
    $logger:notice("heart", (($string_utils:nn(what) + " called unregister_area with queue=") + tostr(queue)) + ", but no such queue exists.");
  elseif (!(what in this.(prop)))
    $logger:notice("heart", (($string_utils:nn(what) + " called unregister_area with queue=") + tostr(queue)) + ", but isn't in that queue.");
  else
    this.(prop) = setremove(this.(prop), what);
    what.heart_queue = 0;
  endif
endif
"Last modified Fri Mar 16 09:52:42 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"report_broken_heartbeat" this none this xd
@program $heart:report_broken_heartbeat
":report_broken_heartbeat(object, info) - Report a traceback from the heartbeat verb on object.";
{what, info} = args;
(caller != this) && raise(E_PERM);
tb = $tb_handler:format_traceback(info[2], info[4], "");
$logger:error("heart", {("Traceback from " + $string_utils:nn(what)) + ":", @tb});
"Last modified Fri Mar 16 09:54:10 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"skip_beat" this none this xd
@program $heart:skip_beat
":skip_beat() - Determine whether the heart should skip a beat.";
(!caller_perms().wizard) && raise(E_PERM);
tasks = $list_utils:slice(queued_tasks());
for t in (this.heartbeat_tasks)
  if (!(t in tasks))
    this.heartbeat_tasks = setremove(this.heartbeat_tasks, t);
  endif
endfor
running = length(this.heartbeat_tasks);
percent = floatstr((tofloat(running) / tofloat(this.highest_queue)) * 100.0, 2);
if (tofloat(percent) >= this.skip_threshold)
  $logger:notice("heart", ((((("Skipping a beat (" + tostr(running)) + "/") + tostr(this.highest_queue)) + " still running, ") + percent) + "%)");
  return 1;
endif
"Last modified Fri Mar 16 10:01:24 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"skip_area_beat" this none this xd
@program $heart:skip_area_beat
":skip_area_beat() - Determine whether the heart should skip an area beat.";
(!caller_perms().wizard) && raise(E_PERM);
tasks = $list_utils:slice(queued_tasks());
for t in (this.area_heartbeat_tasks)
  if (!(t in tasks))
    this.area_heartbeat_tasks = setremove(this.area_heartbeat_tasks, t);
  endif
endfor
running = length(this.area_heartbeat_tasks);
percent = floatstr((tofloat(running) / tofloat(this.highest_area_queue)) * 100.0, 2);
if (tofloat(percent) >= this.skip_threshold)
  $logger:notice("heart", ((((("Skipping an area beat (" + tostr(running)) + "/") + tostr(this.highest_area_queue)) + " still running, ") + percent) + "%)");
  return 1;
endif
"Last modified Fri Mar 16 10:01:51 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"validate_queue" this none this xd
@program $heart:validate_queue
":validate_queue(queue-num, is-area) - Validate, and if necessary, clean up the objects in the specified queue.";
{queue, ?area = 0} = args;
(caller != this) && raise(E_PERM);
prop = ((area ? "area_" | "") + "queue_") + tostr(queue);
clean_queue = {};
modified = 0;
for h in (this.(prop))
  if (!$recycler:valid(h))
    modified = 1;
    $logger:notice("heart", ((("Removed invalid object " + tostr(h)) + " from queue ") + tostr(queue)) + ".");
  elseif ((`typeof(h.heart_queue) ! ANY' != INT) || (h.heart_queue != queue))
    modified = 1;
  elseif (h.f)
    modified = 1;
    $logger:notice("heart", (($string_utils:nn(h) + " is fertile -- removing from queue ") + tostr(queue)) + ".");
    h.heart_queue = -1;
  else
    clean_queue = listappend(clean_queue, h);
  endif
endfor
if (modified)
  this.(prop) = clean_queue;
endif
"Last modified Fri Mar 16 10:02:58 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"heartbeat_owner" this none this xd
@program $heart:heartbeat_owner
":heartbeat_owner(object) - Return the owner of the heartbeat verb on object.";
{what} = args;
(!caller_perms().wizard) && raise(E_PERM);
while (what != $nothing)
  if ((owner = `verb_info(what, "heartbeat")[1] ! ANY => $nothing') != $nothing)
    return owner;
  else
    what = parent(what);
  endif
endwhile
return $nothing;
"Last modified Fri Mar 16 09:47:44 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"report_suspension" this none this xd
@program $heart:report_suspension
":report_suspension(queue-log, queue-num, in-area) - Report that the heart (or the heartbeat verb on the object itself) had to suspend.";
{info, queue, ?area = 0} = args;
(caller != this) && raise(E_PERM);
what = info[$][1];
others = other_ticks = 0;
tick_summary = "";
for i in (info)
  if (i[4] < 5000)
    ++others;
    other_ticks += i[4];
    info = setremove(info, i);
  endif
endfor
if (length(info) > 5)
  info = info[1..5];
endif
info = $list_utils:reverse($list_utils:sort(info, $list_utils:slice(info, 4)));
for i in [1..length(info)]
  tick_summary = (((tick_summary + $string_utils:nn(info[i][1])) + ": ") + tostr(info[i][4])) + ((i < length(info)) ? ", " | "");
endfor
if (others)
  tick_summary = (((tick_summary + "Others (") + tostr(others)) + "): ") + tostr(other_ticks);
endif
$logger:notice("heart", {("Suspended while handling " + $string_utils:nn(what)) + ":", tick_summary});
"Last modified Fri Mar 16 09:58:09 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"@beat-log @area-beat-log" none none none rxd
@program $heart:@beat-log
"@beat-log/@area-beat-log: View beat logs.";
"Number of successfully run tasks, number of failed tasks, number of aborted tasks, number of suspends, minimum, maximum and average ticks.";
player = caller_perms();
if (!player.wizard)
  return player:tell("No.");
endif
area = verb[2..5] == "area";
log_prop = area ? "area_beat_log" | "beat_log";
highest_prop = area ? "highest_area_queue" | "highest_queue";
type = area ? "area beat" | "beat";
if (!this.(log_prop))
  return player:tell(("No " + type) + " information is available.");
endif
player:tell("Please wait.");
queues = 0;
min_ticks = max_ticks = avg_ticks = 0;
queue_info = tick_info = all_tick_info = {};
all_successes = all_errors = all_aborts = all_suspends = 0;
for q in (this.(log_prop))
  queues = queues + 1;
  tick_info = {};
  successes = errors = aborts = suspends = 0;
  for i in (q[2])
    if (i[2] == 1)
      successes = successes + 1;
    elseif (i[2] == 0)
      errors = errors + 1;
    elseif (i[2] == -1)
      aborts = aborts + 1;
    endif
    suspends = suspends + i[3];
    tick_info = {@tick_info, i[4]};
  endfor
  all_successes = all_successes + successes;
  all_errors = all_errors + errors;
  all_aborts = all_aborts + aborts;
  all_suspends = all_suspends + suspends;
  all_tick_info = {@all_tick_info, @tick_info};
  min_ticks = min(@tick_info);
  max_ticks = max(@tick_info);
  avg_ticks = $math_utils:average(@tick_info);
  queue_info = {@queue_info, {q[1], successes, errors, aborts, suspends, min_ticks, max_ticks, avg_ticks}};
  $command_utils:suspend_if_needed(0);
endfor
queue_info = $list_utils:sort(queue_info, $list_utils:slice(queue_info));
min_ticks = min(@all_tick_info);
max_ticks = max(@all_tick_info);
avg_ticks = $math_utils:average(@all_tick_info);
(queues != this.(highest_prop)) && player:tell("Queues run: ", queues, "/", this.(highest_prop));
player:tell("Successes: ", all_successes, "    Errors: ", errors, "    Aborts: ", aborts, "    Suspends: ", suspends);
player:tell("(Ticks) Min: ", min_ticks, "    Max: ", max_ticks, "    Avg: ", avg_ticks);
if ($command_utils:yes_or_no("View the full log? Depending on the number of queues run, this could be spammy."))
  table = {};
  for q in (queue_info)
    table = {@table, $list_utils:map_builtin(q, "tostr")};
    $command_utils:suspend_if_needed(0);
  endfor
  player:tell_lines($string_utils:table_left({"Queue", "Successes", "Aborts", "Errors", "Suspends", "Min", "Max", "Avg"}, table));
endif
"Last modified Fri Mar 16 08:39:18 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"@log-beat @log-area-beat @log-beats" none none none rxd
@program $heart:@log-beat
"Schedule the next beat/area beat to be logged for later analysis.";
player = caller_perms();
if (!player.wizard)
  return player:tell("No.");
endif
if (verb[$ - 4..$] == "beats")
  logged_beats = 2;
elseif (verb[6..9] == "area")
  logged_beats = 1;
else
  logged_beats = 0;
endif
if (((logged_beats == 0) || (logged_beats == 2)) && (this.logging_beat > 0))
  player:tell(("A beat log is already " + ((this.logging_beat == 1) ? "scheduled" | "in progress")) + ".");
  logged_beats = (logged_beats == 0) ? -1 | 1;
endif
if (((logged_beats == 1) || (logged_beats == 2)) && (this.logging_area_beat > 0))
  player:tell(("An area beat log is already " + ((this.logging_area_beat == 1) ? "scheduled" | "in progress")) + ".");
  logged_beats = (logged_beats == 1) ? -1 | ((this.logging_beat == 0) ? 0 | -1);
endif
if (logged_beats > -1)
  if ((logged_beats == 0) || (logged_beats == 2))
    this.logging_beat = 1;
  endif
  if ((logged_beats == 1) || (logged_beats == 2))
    this.logging_area_beat = 1;
  endif
  what = (logged_beats == 0) ? "beat" | ((logged_beats == 1) ? "area beat" | "beats");
  $logger:warning("heart", ((("At the request of " + player:titlec()) + ", the upcoming ") + what) + " will be logged.");
endif
"Last modified Fri Mar 16 09:28:44 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"init_for_core" this none this xd
@program $heart:init_for_core
(!caller_perms().wizard) && raise(E_PERM);
for t in ({@this.heartbeat_tasks, @this.area_heartbeat_tasks})
  `kill_task(t) ! ANY';
endfor
for p in (properties(this))
  if (index(p, "queue_") && (p != "queue_interval"))
    delete_property(this, p);
  endif
endfor
this.heartbeat_tasks = this.area_heartbeat_tasks = {};
this.highest_queue = this.highest_area_queue = 0;
this.beat_log = this.area_beat_log = {};
this.logging_beat = this.logging_area_beat = 0;
this.last_beat = this.last_area_beat = 0;
this.beat_interval = 30;
this.area_beat_interval = 2;
this.queue_interval = 0.125;
this.skip_threshold = 70.0;
this.beat_count = 0;
this.beats_paused = this.area_beats_paused = 0;
this.hearts_per_queue = 25;
this.report_heartbeat_suspends = 1;
"Last modified Fri Mar 16 08:52:36 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"feature_ok" this none this xd
@program $heart:feature_ok
{who} = args;
return who.wizard;
"Last modified Fri Mar 16 09:27:57 2018 CDT by Jason Perino (#91@ThetaCore).";
.
@verb $heart:"server_started" this none this xd
@program $heart:server_started
(caller != #0) && raise(E_PERM);
this:run();
"Last modified Fri Mar 16 09:38:20 2018 CDT by Jason Perino (#91@ThetaCore).";
.
"***finished***
