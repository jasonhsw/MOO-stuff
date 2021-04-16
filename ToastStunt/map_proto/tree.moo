@verb $map_proto:"tree_get" this none this rxd #127
@program $map_proto:tree_get
":tree_get(STRpath[, BOOL convert_types=false[, ? default[, BOOL strict=true[, STR delimiter=\".\"]]]])";
"Or :tree_get(LIST path[, ? default[, BOOL strict]]]): Get the value pointed to by path from a map of maps and/or lists.";
"Path: The path to the value to retrieve. It should either be a string of map keys or list indexes separated by <delimiter>, or a list of keys/indexes.";
"convert_types: If <path> is a string, and <convert_types> is true, attempt to convert each key string into another MOO datatype, such as INT, FLOAT, OBJ, or BOOL.";
"Note that if a key in <path> points to a list, and the next key is not an integer, or a string representation of an integer, then E_TYPE will be raised.";
"Default: The default value to return, if the specified key is not found.";
"strict: If true, all keys in <path> are required to exist. E_RANGE is raised if even one of the keys does not exist. If false, and at least one of the keys does not exist, returns <default>, or raises E_RANGE if no default was specified.";
"delimiter: If <path> is a string, <delimiter> is used to split <path> into a list of strings. If you want to use FLOATs as keys, you may want to change this to something different, such as \"/\".";
path = args[1];
((!((path_type = typeof(path)) in {STR, LIST})) || (!path)) && raise(E_INVARG);
if (path_type == STR)
  {?convert = false, ?default, ?strict = true, ?delim = "."} = args[2..$];
  path = explode(path, delim);
else
  {?default, ?strict = true} = args[2..$];
endif
found = true;
pl = length(path);
for p in [1..pl]
  key = path[p];
  this_type = typeof(this);
  if (((path_type == STR) && convert) && (typeof(new = $string_utils:_toscalar(key)) != STR))
    key = new;
  endif
  key_type = typeof(key);
  if ((this_type == MAP) && maphaskey(this, key))
    this = this[key];
  elseif (((this_type == LIST) && ((key_type == INT) || ((key = toint(key)) > 0))) && (key <= length(this)))
    this = this[key];
  elseif (!(this_type in {MAP, LIST}))
    raise(E_TYPE);
  else
    if ((this_type == LIST) && (!key))
      raise(E_TYPE);
    elseif (strict && (p < pl))
      raise(E_RANGE);
    else
      found = false;
      break;
    endif
  endif
endfor
if (found)
  return this;
else
  return `default ! E_VARNF => raise(E_RANGE)';
endif
"Last modified Fri Apr 16 08:25:44 2021 CDT by Codesmith (#127@SmithyMOO).";
.
@verb $map_proto:"tree_set" this none this rxd #127
@program $map_proto:tree_set
":tree_set(STR path, ? value[, BOOL convert_types=false[, BOOL strict=true[, STR delimiter=\".\"]]])";
"Or :tree_set(LIST path, ? value, [, BOOL strict=true]]): Set the value pointed to by path in a map of maps and/or lists.";
"Path: The path to the value to set. It should either be a string of map keys or list indexes separated by <delimiter>, or a list of keys/indexes.";
"Note that if a key in <path> points to a list, and the next key is not an integer, or a string representation of an integer, then E_TYPE will be raised.";
"Also, if the size of the list is not at least (key - 1), E_RANGE will be raised.";
"value: The value to set at <path> in the tree.";
"convert_types: If <path> is a string, and <convert_types> is true, attempt to convert each key string into another MOO datatype, such as INT, FLOAT, OBJ, or BOOL.";
"strict: If true, all keys/indexes in <path> must exist, or E_RANGE is raised. If false, a new map will be created.";
"delimiter: If <path> is a string, <delimiter> is used to split <path> into a list of strings. If you want to use FLOATs as keys, you may want to change this to something different, such as \"/\".";
path = args[1];
((!((path_type = typeof(path)) in {STR, LIST})) || (!path)) && raise(E_INVARG);
if (path_type == STR)
  {value, ?convert = false, ?strict = true, ?delim = "."} = args[2..$];
  path = explode(path, delim);
else
  {value, ?strict = true} = args[2..$];
endif
found = true;
stack = {{"", this}};
pl = length(path);
for p in [1..pl]
  key = path[p];
  this_type = typeof(this);
  if (((path_type == STR) && convert) && (typeof(new = $string_utils:_toscalar(key)) != STR))
    key = new;
  endif
  key_type = typeof(key);
  if ((this_type == MAP) && maphaskey(this, key))
    next = (p < pl) ? this[key] | value;
    stack = {@stack, {key, next}};
    this = next;
  elseif (((this_type == LIST) && ((key_type == INT) || ((key = toint(key)) > 0))) && (key <= length(this)))
    next = (p < pl) ? this[key] | value;
    stack = {@stack, {key, next}};
    this = next;
  elseif (!(this_type in {MAP, LIST}))
    raise(E_TYPE);
  else
    if ((!strict) && (this_type == MAP))
      next = (p < pl) ? [] | value;
      stack = {@stack, {key, next}};
      this = next;
    elseif ((((!strict) && (this_type == LIST)) && (key > 0)) && (length(this) == (key - 1)))
      next = (p < pl) ? [] | value;
      stack[$][2] = stack[$][2] + next;
      stack = {@stack, {key, next}};
      this = next;
    elseif ((!strict) && ((p < pl) || (this_type == LIST)))
      raise(((this_type == LIST) && (key_type != INT)) ? E_TYPE | E_RANGE);
    else
      found = false;
      break;
    endif
  endif
endfor
if (!found)
  raise(E_RANGE);
endif
if (length(stack) == 1)
  return stack[1][2];
endif
s = length(stack) - 1;
while (s >= 1)
  prev = stack[s][2];
  key = stack[s + 1][1];
  prev[key] = stack[s + 1][2];
  stack[s][2] = prev;
  s = s - 1;
endwhile
return stack[1][2];
"Last modified Fri Apr 16 08:27:14 2021 CDT by Codesmith (#127@SmithyMOO).";
.
@verb $map_proto:"tree_has_key" this none this rxd #127
@program $map_proto:tree_has_key
":tree_has_key(STR path[, BOOL convert_types=false[, BOOL strict=true]])";
"Or :tree_has_key(LIST path[, BOOL strict=true]): Check for the existance  of a key or list index pointed to by <path>";
"convert_types: If <path> is a string, and <convert_types> is true, attempt to convert each key string into another MOO datatype, such as INT, FLOAT, OBJ, or BOOL.";
"Note that if a key in <path> points to a list, and the next key is not an int, an attempt will be made to convert it into an int, even if <convert_types> is false.";
"strict: If true, all keys and/or list indexes in <path> are required to exist. E_RANGE is raised if at least one does not exist. If false, and at least one of the keys does not exist, returns false.";
"Or :tree_get(LIST path[, ? default[, BOOL strict]]]): Get the value pointed to by path from a map of maps and/or lists.";
"Path: The path to the value to retrieve. It should either be a string of map keys or list indexes separated by <delimiter>, or a list of keys/indexes.";
"Note that if a key in <path> points to a list, and the next key is not an integer, or a string representation of an integer, then E_TYPE will be raised.";
"convert_types: If <path> is a string, and <convert_types> is true, attempt to convert each key string into another MOO datatype, such as INT, FLOAT, OBJ, or BOOL.";
"Default: The default value to return, if the specified key is not found.";
"strict: If true, all keys in <path> are required to exist. E_RANGE is raised if even one of the keys does not exist. If false, and at least one of the keys does not exist, returns <default>, or raises E_RANGE if no default was specified.";
"delimiter: If <path> is a string, <delimiter> is used to split <path> into a list of strings. If you want to use FLOATs as keys, you may want to change this to something different, such as \"/\".";
path = args[1];
((!((path_type = typeof(path)) in {STR, LIST})) || (!path)) && raise(E_INVARG);
if (path_type == STR)
  {?convert = false, ?strict = true, ?delim = "."} = args[2..$];
  path = explode(path, delim);
else
  {?strict = true} = args[2..$];
endif
found = true;
pl = length(path);
for p in [1..pl]
  key = path[p];
  this_type = typeof(this);
  if (((path_type == STR) && convert) && (typeof(new = $string_utils:_toscalar(key)) != STR))
    key = new;
  endif
  key_type = typeof(key);
  if ((this_type == MAP) && maphaskey(this, key))
    this = this[key];
  elseif (((this_type == LIST) && ((key_type == INT) || ((key = toint(key)) > 0))) && (key <= length(this)))
    this = this[key];
  elseif (!(this_type in {MAP, LIST}))
    raise(E_TYPE);
  elseif ((this_type == LIST) && (!key))
    raise(E_TYPE);
  elseif ((p < pl) && strict)
    raise(E_RANGE);
  else
    found = false;
    break;
  endif
endfor
return found;
"Last modified Fri Apr 16 08:28:07 2021 CDT by Codesmith (#127@SmithyMOO).";
.
@verb $map_proto:"tree_delete" this none this rxd #127
@program $map_proto:tree_delete
":tree_delete(STRpath[, BOOL convert_types=false[, STR delimiter=\".\"]]]])";
"Or :tree_delete(LIST path): Delete the key pointed to by path in a map of maps and/or lists.";
"Path: The path to the value to set. It should either be a string of map keys or list indexes separated by <delimiter>, or a list of keys/indexes.";
"convert_types: If <path> is a string, and <convert_types> is true, attempt to convert each key string into another MOO datatype, such as INT, FLOAT, OBJ, or BOOL.";
"Note that if a key in <path> points to a list, and the next key is not an integer, or a string representation of an integer, then E_TYPE will be raised.";
"Also, if the size of the list is not at least (key - 1), E_RANGE will be raised.";
"delimiter: If <path> is a string, <delimiter> is used to split <path> into a list of strings. If you want to use FLOATs as keys, you may want to change this to something different, such as \"/\".";
path = args[1];
"Raises: E_RANGE if any of the keys/indexes in <path> do not exist.";
((!((path_type = typeof(path)) in {STR, LIST})) || (!path)) && raise(E_INVARG);
if (path_type == STR)
  {?convert = false, ?delim = "."} = args[2..$];
  path = explode(path, delim);
endif
stack = {{"", this}};
pl = length(path);
for p in [1..pl]
  key = path[p];
  this_type = typeof(this);
  if (((path_type == STR) && convert) && (typeof(new = $string_utils:_toscalar(key)) != STR))
    key = new;
  endif
  key_type = typeof(key);
  if ((this_type == MAP) && maphaskey(this, key))
    if (p < pl)
      stack = {@stack, {key, this[key]}};
      this = this[key];
    endif
  elseif (((this_type == LIST) && ((key_type == INT) || ((key = toint(key)) > 0))) && (key <= length(this)))
    if (p < pl)
      stack = {@stack, {key, this[key]}};
      this = this[key];
    endif
  elseif (!(this_type in {MAP, LIST}))
    raise(E_TYPE);
  else
    raise(((this_type == LIST) && (key_type != INT)) ? E_TYPE | E_RANGE);
  endif
endfor
if (typeof(stack[$][2]) == MAP)
  stack[$][2] = mapdelete(stack[$][2], key);
else
  stack[$][2] = {@stack[$][2][1..key - 1], @stack[$][2][key + 1..$]};
endif
if (length(stack) == 1)
  return stack[1][2];
endif
s = length(stack) - 1;
while (s >= 1)
  prev = stack[s][2];
  key = stack[s + 1][1];
  prev[key] = stack[s + 1][2];
  stack[s][2] = prev;
  s = s - 1;
endwhile
return stack[1][2];
"Last modified Fri Apr 16 08:30:57 2021 CDT by Codesmith (#127@SmithyMOO).";
.
"***finished***
