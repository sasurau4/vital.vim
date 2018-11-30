let s:save_cpo = &cpo
set cpo&vim

" NOTE: These are verbose to avoid key's unintentional confliction ;(
let s:SOME_KEY = 'vital_data_optional_some' | lockvar s:SOME_KEY
let s:NONE_KEY = 'vital_data_optional_none' | lockvar s:NONE_KEY

function! s:_require_optional(...) abort
  for x in a:000
    if !s:is_optional(x)
      throw printf('vital: Data.Optional: Not an optional value `%s`', string(x))
    endif
    unlet x
  endfor
endfunction

function! s:_require_optionals(xs) abort
  call call(function('s:_require_optional'), a:xs)
endfunction

function! s:none() abort
  let none = {}
  let none[s:NONE_KEY] = {}
  return none
endfunction

function! s:some(v) abort
  let some = {}
  let some[s:SOME_KEY] = a:v
  return some
endfunction

function! s:new(v, ...) abort
  if exists('v:null')
    return a:v == v:null || (a:0 > 0 && a:v == a:1)
          \ ? s:none()
          \ : s:some(a:v)
  elseif a:0 > 0
    return a:v == a:1
          \ ? s:none()
          \ : s:some(a:v)
  else
      throw 'vital: Data.Optional: both v:null and {null} are missing'
  endif
endfunction

function! s:is_optional(v) abort
  return s:empty(a:v) || s:exists(a:v)
endfunction

function! s:empty(o) abort
  return (type(a:o) is type({})) && has_key(a:o, s:NONE_KEY)
endfunction

function! s:exists(o) abort
  return (type(a:o) is type({})) && has_key(a:o, s:SOME_KEY)
endfunction

function! s:set(o, v) abort
  if s:empty(a:o)
    unlet a:o[s:NONE_KEY]
  endif
  let a:o[s:SOME_KEY] = a:v
endfunction

function! s:unset(o) abort
  if s:exists(a:o)
    unlet a:o[s:SOME_KEY]
  endif
  let a:o[s:NONE_KEY] = {}
endfunction

function! s:get(o) abort
  if s:empty(a:o)
    throw 'vital: Data.Optional: An empty Data.Optional value'
  endif
  return a:o[s:SOME_KEY]
endfunction

function! s:get_unsafe(o) abort
  return a:o[s:SOME_KEY]
endfunction

function! s:get_or(o, alt) abort
  return get(a:o, s:SOME_KEY, a:alt())
endfunction

function! s:has(o, type) abort
  return !s:empty(a:o) && (type(a:o[s:SOME_KEY]) is a:type)
endfunction

function! s:apply(f, ...) abort
  call s:_require_optionals(a:000)
  let args = []

  for x in a:000
    if s:empty(x)
      return s:none()
    endif
    call add(args, s:get(x))
    unlet x
  endfor

  return s:some(call(a:f, args))
endfunction

function! s:map(x, f) abort
  if s:empty(a:x)
    return s:none()
  endif
  let naked_result = call(a:f, [s:get(a:x)])
  return s:some(naked_result)
endfunction

function! s:bind(f, ...) abort
  call s:_require_optionals(a:000)
  let args = []

  for x in a:000
    if s:empty(x)
      return s:none()
    endif
    call add(args, s:get(x))
  endfor

  return call(a:f, args)
endfunction

let s:FLATTEN_DEFAULT_LIMIT = 1 | lockvar s:FLATTEN_DEFAULT_LIMIT

function! s:flatten(x, ...) abort
  let limit = get(a:000, 0, s:FLATTEN_DEFAULT_LIMIT)

  if limit is 0
    return s:_flatten_fully(a:x)
  endif

  return s:_flatten_with_limit(a:x, limit)
endfunction

" Returns true for some({non optional}).
" Otherwies, returns false.
" (Returns false for none().)
function! s:_has_a_nest(x) abort
  return s:exists(a:x) && !s:is_optional(s:get(a:x))
endfunction

function! s:_flatten_with_limit(x, limit) abort
  if s:empty(a:x) || s:_has_a_nest(a:x) || (a:limit <= 0)
    return a:x
  endif
  return s:_flatten_with_limit(s:get(a:x), a:limit - 1)
endfunction

function! s:_flatten_fully(x) abort
  if s:empty(a:x) || s:_has_a_nest(a:x)
    return a:x
  endif
  return s:_flatten_fully(s:get(a:x))
endfunction

function! s:_echo(x) abort
  if s:empty(a:x)
    echo 'None'
    return
  endif
  echo 'Some (' . s:get(a:x) . ')'
endfunction

function! s:echo(o, ...) abort
  call s:_require_optional(a:o)

  execute 'echohl' get(a:000, 0, 'None')
  call s:map(a:o, function('s:_echo'))
  echohl None
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
