#!/usr/bin/env zsh
# GRYPS 1.4.1 — Zsh: składnia _gryps i kandydaci (compadd podstawiony atrapą,
# więc filtr prefiksu nie jest tu sprawdzany — tylko zbiór i liczba kandydatów).
emulate -L zsh
ROOT=${0:A:h:h}
zsh -n "$ROOT/completions/_gryps" || { print '  ❌ składnia completions/_gryps'; exit 1 }
fpath=("$ROOT/completions" $fpath)
autoload -Uz _gryps
typeset -ga GOT
compadd() { local -a a; a=("$@"); local i=${a[(i)--]}; GOT+=("${(@)a[i+1,-1]}") }
_describe() { GOT+=("describe:$2") }
_files() { GOT+=(files) }
_message() { GOT+=(message) }
integer pass=0 fail=0
check() {
  local want=$1; shift
  GOT=(); words=("$@"); CURRENT=$#; _gryps
  if [[ $want == !* ]]; then
    if (( ${GOT[(Ie)${want#!}]} )); then print "  ❌ $* -> nie powinno być ${want#!}"; (( fail++ )); return; fi
  elif ! (( ${GOT[(Ie)$want]} )); then print "  ❌ $* -> brak $want"; (( fail++ )); return; fi
  print "  ✅ $* -> $want"; (( pass++ ))
}
for name in skitraj odklep wykipruj tabor podkopsaj kartoteka; do check $name gryps ''; done
check '!skitrac' gryps ''
check files gryps skitraj -- src/
check files gryps wykipruj -- b
check message gryps odklep ''
check skitraj gryps kmina ''
GOT=(); words=(gryps ''); CURRENT=2; _gryps
if (( ${#GOT} == 44 )); then print '  ✅ 44 grypsy w grupach Zsh'; (( pass++ ))
else print "  ❌ liczba grypsów w Zsh: ${#GOT}"; (( fail++ )); fi
print "Zsh TAB: $pass/$(( pass + fail )) zaliczonych"
(( fail == 0 ))
