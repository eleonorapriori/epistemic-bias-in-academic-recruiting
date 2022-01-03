turtles-own [età cv scuola-pensiero]
breed[professori professore]
breed[ricercatori ricercatore]
professori-own [commissario]
ricercatori-own [precariato abilitazione valutazione]
globals [
  pensionamenti       ;; quanti pensionamenti nell'anno (azzerato ogni tick)
  concorsi-aperti     ;; posti vacanti (dopo applicazione % turnover, stock)
  timer-ricercatori   ;; timer di respawn
  estinzione-1        ;; - variabile di solo output
  estinzione-2        ;; - variabile di solo output
  estinzione-3        ;; - variabile di solo output
  estinzioni          ;; - variabile di solo output
  dati-export         ;; - variabile di solo output
  contatore           ;; per simulazioni consecutive
  csv-file-name-out   ;; nome file csv di export
  bias-pubblicazione-min  ;; equal to 0
  cv-point-turn-max   ;; equal to 5
  soglia-temp         ;; soglia o mediana da superare per abilitazione
  ]

;; -----------------------------------------------------------------------------------

to setup

  ;; funzione di setup

  ;;seed per numeri casuali manuale o automatico

  if seed-choice = "random seed" [random-seed new-seed]
  if seed-choice = "input seed" [random-seed seed-input]
  if seed-choice = "incremental" [random-seed (seed-input + contatore)]

  ;; pulisco variabili

  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  set pensionamenti 0
  set timer-ricercatori 0
  set concorsi-aperti 0
  set estinzioni 0
  set estinzione-1 0
  set estinzione-2 0
  set estinzione-3 0
  set soglia-temp 0
  set bias-pubblicazione-min 0
  ;set cv-point-turn-max 5 ;; originale
  set cv-point-turn-max 10
  reset-ticks
  if reclutamento = "asn-soglia" [set soglia-temp soglia]

  if dati-export = 0 [set dati-export (list [] [] [])]

  ;; creo professori

  run [crea-prof "scuola-1" scuola-1]
  run [crea-prof "scuola-2" scuola-2]
  run [crea-prof "scuola-3" scuola-3]

  run [crea-ricercatori-start "scuola-1"]
  run [crea-ricercatori-start "scuola-2"]
  run [crea-ricercatori-start "scuola-3"]

  set timer-ricercatori incremento-ricercatori

end

;; -----------------------------------------------------------------------------------

to crea-prof [scuola n]

  ;; crea professori di partenza, usata solo in setup

  create-professori n [
    set età (35 + random(35))
    set cv cv-years (età - 28) scuola ;; per la mediana produce 0 abilitati
    ;;set cv cv-years 10 scuola ;; alternativo per mediana
    set scuola-pensiero scuola
    ]
end

;; -----------------------------------------------------------------------------------

to bandisci-concorso

  ;; concorso di assunzione

  ;; compongo commissione

  let comm 1
  ask n-of n-commissari professori [
    set commissario comm
    set comm (comm + 1)
  ]

  ;; formulo valutazioni

  ask ricercatori [
    set valutazione 0
    let i 1
    while [i <= n-commissari][
      let bias 1
      if [scuola-pensiero] of one-of professori with [commissario = i] = scuola-pensiero [set bias (1 + bias-valutazione)]
      set valutazione (valutazione + cv * (random-float(rumore-max - rumore-min) + rumore-min) * bias)
      set i (i + 1)
    ]
  ]

  ;; promuovo il vincitore

  ifelse reclutamento = "concorso"
     [ask max-one-of ricercatori [valutazione] [set breed professori]]
     [ask max-one-of ricercatori with [abilitazione > 0] [valutazione] [set breed professori]]

  ;; riduco punti organico e sciolgo commissione

  set concorsi-aperti (concorsi-aperti - 1)
  ask professori with [commissario > 0][set commissario 0]

end

;; -----------------------------------------------------------------------------------

to crea-ricercatori-start [scuola]

  ;; crea ricercatori (uno per prof), usata al primo tick

  create-ricercatori ((count professori with [scuola-pensiero = scuola]) * 1)[
    set precariato random(10)
    set età (24 + random(7) + precariato)
    set cv cv-years precariato scuola
    set scuola-pensiero scuola
  ]

end

;; -----------------------------------------------------------------------------------

to crea-ricercatori [scuola]

  ;; crea ricercatori (uno per prof), usata ad intervalli regolari definiti da incremento-ricercatori (ogni quanti tick creo nuovi ricercatori?)

  create-ricercatori (count professori with [scuola-pensiero = scuola])[
    set precariato 0
    set età (24 + random(7))
    set cv 0
    set scuola-pensiero scuola
  ]

end

;; -----------------------------------------------------------------------------------

to-report cv-years [n scuola]

  ;; per ricercatori e professori neonati, serve a calcolare il cv come random(0-5) per ogni anno di carriera

  let i 0
  let cvy 0
  while [i < n][
    set cvy (cvy + (random(cv-point-turn-max + 1) * bias-pubblicazione scuola))
    set i (i + 1)]
  report cvy

end

;; -----------------------------------------------------------------------------------

to-report bias-pubblicazione [scuola]

  ;; calcolo il bias di pubblicazione, è un coefficiente dell'incremento annuo del cv che dipende linearmente dalla percentuale di agenti della scuola data sul totale, varia tra un minimo ed un massimo definiti da input

  let bias-p 1
  set bias-p (bias-p + (((bias-pubblicazione-max - bias-pubblicazione-min) * (count turtles with [scuola-pensiero = scuola] / count turtles)) + bias-pubblicazione-min))
  report bias-p

end

;; -----------------------------------------------------------------------------------

to update-export

  let j 0

  while [j < length(dati-export)] [
    if length(item j dati-export) <= ticks [set dati-export replace-item j dati-export (lput ([]) (item j dati-export))]
    set j (j + 1)
  ]

  set dati-export replace-item 0 dati-export (replace-item ticks (item 0 dati-export) (lput (count professori with [scuola-pensiero = "scuola-1"]) (item ticks (item 0 dati-export))))

  set dati-export replace-item 1 dati-export (replace-item ticks (item 1 dati-export) (lput (count professori with [scuola-pensiero = "scuola-2"]) (item ticks (item 1 dati-export))))

  set dati-export replace-item 2 dati-export (replace-item ticks (item 2 dati-export) (lput (count professori with [scuola-pensiero = "scuola-3"]) (item ticks (item 2 dati-export))))

end

;; -----------------------------------------------------------------------------------

to go

  ;; funzione go

  ;; --- invecchio tutti, scadono abilitazioni, elimino pensionati e precari non rinnovabili ---

  ask turtles [
    set età (età + 1)
    ;; set cv (cv + (random(cv-point-turn-max + 1) * bias-pubblicazione scuola-pensiero))
    set cv (cv + (random-normal (cv-point-turn-max / 2) (cv-point-turn-max / 6) * bias-pubblicazione scuola-pensiero))
  ]
  ask ricercatori [
    set precariato (precariato + 1)
    if abilitazione > 0 [set abilitazione (abilitazione - 1)]
    if precariato = 13 [die]
  ]
  ask professori [
    if età = 70 [
      set pensionamenti (pensionamenti + 1)
      die]
  ]

  ;; --- controllo che siano rimasti professori sufficienti per continuare la simulazione (per turnover < 1) ---

  if count professori < n-commissari [
    output-print word "\nProfessori insufficienti \nper un concorso al tick " ticks
    run [end-simulation] stop]

  if count professori < n-commissari-asn and reclutamento != "concorso"[
    output-print word "\nProfessori insufficienti \nper un concorso asn al tick " ticks
    run [end-simulation] stop]

  ;; --- se è il momento creo nuovi ricercatori ---

  if timer-ricercatori = 0 [
    run [crea-ricercatori "scuola-1"]
    run [crea-ricercatori "scuola-2"]
    run [crea-ricercatori "scuola-3"]
    set timer-ricercatori incremento-ricercatori
  ]
  set timer-ricercatori (timer-ricercatori - 1)

  ;; --- se mediana la calcolo ---

  if reclutamento = "asn-mediana" [
    set soglia-temp median [cv] of professori
  ]

  ;; --- asn ---

  if reclutamento != "concorso" [
    run[bandisci-asn]
  ]

  ;; --- applico turnover e bandisco concorsi di assunzione ---

  set concorsi-aperti (concorsi-aperti + (pensionamenti * turn-over))
  set pensionamenti 0

  let i 0
  while [concorsi-aperti >= 1 and i = 0][
    ifelse (reclutamento != "concorso")
      [ifelse(count ricercatori with [abilitazione > 0] > 0)[run [bandisci-concorso]][set i 1]]
      [run[bandisci-concorso]]
  ]

  ;; --- check estinzioni scuole di pensiero ---

  if estinzione-1 = 0 and count professori with [scuola-pensiero = "scuola-1"] = 0 and scuola-1 > 0
     [set estinzione-1 ticks
      set estinzioni (estinzioni + 1)
      output-print word "\nEstinzione scuola-1 al tick " ticks]
  if estinzione-2 = 0 and count professori with [scuola-pensiero = "scuola-2"] = 0 and scuola-2 > 0
     [set estinzione-2 ticks
      set estinzioni (estinzioni + 1)
      output-print word "\nEstinzione scuola-2 al tick " ticks]
  if estinzione-3 = 0 and count professori with [scuola-pensiero = "scuola-3"] = 0 and scuola-3 > 0
     [set estinzione-3 ticks
      set estinzioni (estinzioni + 1)
      output-print word "\nEstinzione scuola-3 al tick " ticks]

  ;; --- valuto se fermarmi (rimane una sola scuola di pensiero [solo output, no stop], opure ho impostato un limite massimo di tick ---

  ;if estinzioni = 2 [output-print word "\nSimulazione interrotta, \nuna sola scuola di pensiero \nrimanente al tick " ticks
  ;  ;;ifelse times < 2 or contatore = times [run [end-simulation] stop][run [end-simulation]]]
  ;  run [end-simulation]
  ;  stop]

  if estinzioni = 2 [
    output-print word "\nUna sola scuola di pensiero \nrimanente al tick " ticks
    set estinzioni -1
  ]

  if until > 0 and ticks = until [
    ;;ifelse times < 2 or contatore = times [run [end-simulation] stop][run [end-simulation]]]
    run [end-simulation]
    stop]

  ;run[update-export] ;aumenta in maniera incrementale dimensioni output

  tick

end

;; -----------------------------------------------------------------------------------

to end-simulation

  ;; funzione che termina la simulazione, esporta i dati in csv se richiesto e, se necessario, fa partire una nuova simulazione

  csv-output
  output-print word "\n---- Simulazione " word contatore " terminata ----"
  set contatore (contatore + 1)

  run [setup]
  loop [ifelse contatore < (times + 1) [go][stop]]
  stop

end

;; -----------------------------------------------------------------------------------

to csv-output

  ;; funzione che esporta i dati in csv

  ;;if csv-export [
  ;;  ifelse csv-output-file-name = "" [set csv-file-name-out "simulazione"][set csv-file-name-out csv-output-file-name]
  ;;  ifelse substring csv-file-name-out ((length csv-file-name-out) - 4) (length csv-file-name-out) != ".csv"
  ;;     [set csv-file-name-out (word csv-file-name-out "-" (contatore) ".csv")]
  ;;     [set csv-file-name-out substring csv-file-name-out 0 ((length csv-file-name-out) - 4)
  ;;      set csv-file-name-out (word csv-file-name-out "-" (contatore) ".csv")]
  ;;  export-world csv-file-name-out
  ;;]

  if csv-export [
    let out (list reclutamento "-" turn-over "-" bias-valutazione "-" bias-pubblicazione-max "-" incremento-ricercatori "-" n-commissari "-" n-commissari-asn "-" pareri "-" durata-abilitazione "-" soglia "-" scuola-1 "-" scuola-2 "-" scuola-3 "-" contatore ".csv")
    set csv-file-name-out reduce word out
    export-world csv-file-name-out

    ;if contatore = times [
    ;  set csv-file-name-out (word "export-" csv-file-name-out)
    ;  export-plot "plot-dati-export" csv-file-name-out
    ;]
  ]

end

;; -----------------------------------------------------------------------------------

to bandisci-asn

  ;; concorso asn

  ;; compongo commissione

  let comm 1
  ask n-of n-commissari-asn professori [
    set commissario comm
    set comm (comm + 1)
  ]

  ;; formulo valutazioni e abilito

  ask ricercatori with [abilitazione = 0][
    set valutazione 0
    let i 1

    ;;output-print word "Ricercatore: " who
    ;;output-print word "CV: " cv

    while [i <= n-commissari-asn][
      let bias 1
      if [scuola-pensiero] of one-of professori with [commissario = i] = scuola-pensiero [set bias (1 + bias-valutazione)]
      set valutazione (cv * (random-float(rumore-max - rumore-min) + rumore-min) * bias)
      if valutazione > soglia-temp [
        set abilitazione (abilitazione - 1)
      ]
      ;;output-print word "Valutazione" word i word ": " valutazione
      set i (i + 1)
    ]

    ifelse abilitazione <= (pareri * -1)
      [set abilitazione durata-abilitazione]
      [set abilitazione 0]
  ]

  ;; sciolgo commissione

  ask professori with [commissario > 0][set commissario 0]

end

;; -----------------------------------------------------------------------------------

to reset
  clear-output
  clear-globals
  if contatore = 0 [set contatore (contatore + 1)]
end
@#$#@#$#@
GRAPHICS-WINDOW
1130
11
1300
182
-1
-1
162.0
1
10
1
1
1
0
1
1
1
0
0
0
0
1
1
1
ticks
30.0

CHOOSER
11
11
149
56
reclutamento
reclutamento
"concorso" "asn-mediana" "asn-soglia"
2

SLIDER
11
62
183
95
turn-over
turn-over
0.5
1.5
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
11
101
183
134
bias-valutazione
bias-valutazione
0
0.5
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
10
180
182
213
incremento-ricercatori
incremento-ricercatori
1
5
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
164
25
217
43
se asn -->
11
0.0
1

SLIDER
227
11
399
44
n-commissari-asn
n-commissari-asn
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
227
50
399
83
pareri
pareri
1
n-commissari-asn
4.0
1
1
NIL
HORIZONTAL

SLIDER
10
219
182
252
n-commissari
n-commissari
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
10
258
182
291
rumore-min
rumore-min
0
2
0.9
0.05
1
NIL
HORIZONTAL

SLIDER
10
295
182
328
rumore-max
rumore-max
0
2
1.1
0.05
1
NIL
HORIZONTAL

BUTTON
10
414
73
447
setup
setup\nif contatore = 0 [set contatore (contatore + 1)]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
188
180
360
213
scuola-1
scuola-1
0
300
50.0
1
1
NIL
HORIZONTAL

SLIDER
188
220
360
253
scuola-2
scuola-2
0
300
0.0
1
1
NIL
HORIZONTAL

SLIDER
188
258
360
291
scuola-3
scuola-3
0
300
50.0
1
1
NIL
HORIZONTAL

PLOT
413
12
683
162
professori
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"scuola-1" 1.0 0 -14070903 true "" "plot count professori with [scuola-pensiero = \"scuola-1\"]"
"scuola-2" 1.0 0 -14439633 true "" "plot count professori with [scuola-pensiero = \"scuola-2\"]"
"scuola-3" 1.0 0 -5298144 true "" "plot count professori with [scuola-pensiero = \"scuola-3\"]"
"totali" 1.0 0 -16777216 true "" "plot count professori"

BUTTON
82
394
145
427
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
413
170
683
320
ricercatori
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"scuola-1" 1.0 0 -14070903 true "" "plot count ricercatori with [scuola-pensiero = \"scuola-1\"]"
"scuola-2" 1.0 0 -14439633 true "" "plot count ricercatori with [scuola-pensiero = \"scuola-2\"]"
"scuola-3" 1.0 0 -5298144 true "" "plot count ricercatori with [scuola-pensiero = \"scuola-3\"]"
"totali" 1.0 0 -16777216 true "" "plot count ricercatori"

SLIDER
227
89
399
122
durata-abilitazione
durata-abilitazione
1
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
11
140
182
173
bias-pubblicazione-max
bias-pubblicazione-max
bias-pubblicazione-min
0.5
0.2
0.1
1
NIL
HORIZONTAL

CHOOSER
9
455
101
500
seed-choice
seed-choice
"random seed" "input seed" "incremental"
0

INPUTBOX
110
448
265
508
seed-input
35.0
1
0
Number

OUTPUT
909
213
1328
532
12

INPUTBOX
151
378
214
438
until
100.0
1
0
Number

SWITCH
278
404
394
437
csv-export
csv-export
1
1
-1000

INPUTBOX
221
378
271
438
times
1000.0
1
0
Number

BUTTON
10
377
73
410
reset
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
275
448
522
508
csv-output-file-name
NIL
1
0
String

SLIDER
226
129
398
162
soglia
soglia
1
50
20.0
1
1
NIL
HORIZONTAL

PLOT
693
13
893
163
mediana
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"mediana" 1.0 0 -16777216 true "" "if reclutamento = \"asn-mediana\" [plot soglia-temp]"

PLOT
694
170
894
320
concorsi aperti
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"concorsi aperti" 1.0 0 -16777216 true "" "plot concorsi-aperti"

PLOT
696
329
896
479
abilitati
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14070903 true "" "plot count ricercatori with [scuola-pensiero = \"scuola-1\" and abilitazione > 0]"
"pen-1" 1.0 0 -12087248 true "" "plot count ricercatori with [scuola-pensiero = \"scuola-2\" and abilitazione > 0]"
"pen-2" 1.0 0 -2674135 true "" "plot count ricercatori with [scuola-pensiero = \"scuola-3\" and abilitazione > 0]"
"pen-3" 1.0 0 -16777216 true "" "plot count ricercatori with [abilitazione > 0]"

MONITOR
403
392
523
437
simulazione numero
contatore
0
1
11

PLOT
17
527
656
748
cv-distro
NIL
NIL
0.0
60.0
0.0
10.0
true
true
"" ""
PENS
"pen-1" 1.0 1 -13791810 true "" "histogram [cv] of ricercatori with [scuola-pensiero = \"scuola-1\"]"
"pen-2" 1.0 1 -13840069 true "" "histogram [cv] of ricercatori with [scuola-pensiero = \"scuola-2\"]"
"pen-3" 1.0 1 -2674135 true "" "histogram [cv] of ricercatori with [scuola-pensiero = \"scuola-3\"]"

BUTTON
594
484
657
517
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
899
12
1118
196
abilitati/totale
NIL
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if (count ricercatori) > 0 [plot count ricercatori with [abilitazione > 0] / count ricercatori]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="01 - #concorso" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;concorso&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="02 - #asn" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;asn-soglia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari-asn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pareri">
      <value value="4"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soglia">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="durata-abilitazione">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="03 - #concorso +bias" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;concorso&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="04 - #asn +bias" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;asn-soglia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari-asn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pareri">
      <value value="4"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soglia">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="durata-abilitazione">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="05 - #concorso pub" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;concorso&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="06 - #asn pub" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;asn-soglia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari-asn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pareri">
      <value value="4"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soglia">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="durata-abilitazione">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="07 - #concorso -turn" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;concorso&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="08 - #asn -turn" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;asn-soglia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari-asn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pareri">
      <value value="4"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soglia">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="durata-abilitazione">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="09 - #concorso +turn" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;concorso&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="10 - #asn +turn" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;asn-soglia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari-asn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pareri">
      <value value="4"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soglia">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="durata-abilitazione">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="11 - #asn +soglia" repetitions="1" runMetricsEveryStep="false">
    <setup>reset
setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="until">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-choice">
      <value value="&quot;random seed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="csv-export">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reclutamento">
      <value value="&quot;asn-soglia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari-asn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pareri">
      <value value="4"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="soglia">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turn-over">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incremento-ricercatori">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-commissari">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-pubblicazione-max">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bias-valutazione">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scuola-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-min">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumore-max">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="durata-abilitazione">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
