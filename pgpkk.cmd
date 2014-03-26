/* PGPKK.CMD V 1.01 */

call rxfuncadd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

parse arg Param kommando
'prompt $p$E[0;'34';'47';'5';'5'm]'
echo off
'cls'
say '[30m[1A'
if (pos('-xa',kommando) <> 0) | (pos('-a',kommando) <> 0) then do
 kommando = translate(kommando,'/', '#')
end
/* for debugging remove the comment in the next line */
/* say Param kommando */
kommando
if param = '/P' then pause
exit
