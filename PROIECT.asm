.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc



includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 800
area_height EQU 700
area DD 0



counter DD 0 ; numara evenimentele de tip timer


arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20



symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include Patrat_colorat.inc


;;;;;;;;;;;;;;;;;;;;;;;;;;;; coordonatele patratului mare
patrat_x EQU 140
patrat_y EQU 50
patrat_size EQU 360


;;;;;;;;;;;;;;;;;;;;;;;;;;;; dimensiunile pt 1/4 dintr-un patratel, pt colorare 
patrat_colorat_width EQU 45
patrat_colorat_height EQU 45
patrat_colorat_desen DD 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;; index-ul obtinut prin calcule mai jos, trebuie pus intr-o variabila pt a-l putea folosi in alte calcule 
index_coloana DD 0
index_linie DD 0
dimensiune_patrat DD 90


	   
matrix DB 0, 0, 0, 0
       DB 0, 0, 0, 0
       DB 0, 0, 0, 0
       DB 0, 0, 0, 0


	   
;;;;;;;;;;;;;;;;;;;;;;;;;; rezultatele calculelor coordonatelor patratului in care s-a dat click 
calcul_1 DD 0
calcul_2 DD 0
valoare4_ajutor_calcul DD 4



;;;;;;;;;;;;;;;;;;;;;;;;;; countere pt a vedea cate vapoare au mai ramas, cate lovituri cu succes/ ratari s-au facut
counter_vapoare_ramase DD 9
counter_lovituri_succes DD 0
counter_lovituri_ratate DD 0



;;;;;;;;;;;;;;;;;;;;;;;;;; pentru functia random

nr_coloane DD 4
coord_random_x DD 0
coord_random_y DD 0
counter_vapoare_random DD 0


.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; cod standard candvas
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
push ebp
mov ebp, esp
pusha

mov eax, [ebp+arg1] ; citim simbolul de afisat
cmp eax, 'A'
jl make_digit
cmp eax, 'Z'
jg make_digit
sub eax, 'A'
lea esi, letters
jmp draw_text


make_digit:
cmp eax, '0'
jl make_space
cmp eax, '9'
jg make_space
sub eax, '0'
lea esi, digits
jmp draw_text
make_space:
mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
lea esi, letters

draw_text:
mov ebx, symbol_width
mul ebx
mov ebx, symbol_height
mul ebx
add esi, eax
mov ecx, symbol_height
bucla_simbol_linii:
mov edi, [ebp+arg2] ; pointer la matricea de pixeli
mov eax, [ebp+arg4] ; pointer la coord y
add eax, symbol_height
sub eax, ecx
mov ebx, area_width
mul ebx
add eax, [ebp+arg3] ; pointer la coord x
shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
add edi, eax
push ecx
mov ecx, symbol_width
bucla_simbol_coloane:
cmp byte ptr [esi], 0
je simbol_pixel_alb
mov dword ptr [edi], 0FFFFFFh
jmp simbol_pixel_next
simbol_pixel_alb:
mov dword ptr [edi], 0
simbol_pixel_next:
inc esi
add edi, 4
loop bucla_simbol_coloane
pop ecx
loop bucla_simbol_linii
popa
mov esp, ebp
pop ebp
ret
make_text endp





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Generare pozitii random in matrice

generate_random proc 
push ebp
mov ebp, esp
pusha

generare_pereche_random :

rdtsc  ;ia o valoare random si o pune in eax

mov edx, 0
; facem operatia eax % nr coloane care ne va rezulta o coordonata pe x
div nr_coloane   ; prin operatia div se pune catul in EAX, iar restul in EDX
mov coord_random_x, edx  
mov esi, coord_random_x

; facem operatia eax % nr coloane care ne va rezulta o coordonata pe y
rdtsc
mov edx, 0
div nr_coloane
mov coord_random_y, edx
mov edi, coord_random_y

cmp matrix[esi*4][edi], 1
je generare_pereche_random
cmp matrix[esi*4][edi], 0
je spatiu_liber

spatiu_liber:

	mov matrix[esi*4][edi], 1
	add counter_vapoare_random, 1
	cmp counter_vapoare_random, 9
	jne generare_pereche_random
	je final
	
final :

	popa
	mov esp, ebp
	pop ebp
	ret
generate_random endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; procedura si macro pt colorare patrat rosu

make_patrat_colorat_rosu proc
push ebp
mov ebp, esp
pusha

mov eax, [ebp+arg1] ; citim simbolul de afisat
lea esi, Patrat_colorat
jmp draw_patrat


draw_patrat:
mov ebx, patrat_colorat_width
mul ebx
mov ebx, patrat_colorat_height
mul ebx
add esi, eax
mov ecx, patrat_colorat_height

bucla_simbol_linii:
mov edi, [ebp+arg2] ; pointer la matricea de pixeli
mov eax, [ebp+arg4] ; pointer la coord y
add eax, patrat_colorat_height
sub eax, ecx
mov ebx, area_width
mul ebx
add eax, [ebp+arg3] ; pointer la coord x
shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
add edi, eax
push ecx
mov ecx, patrat_colorat_width
bucla_simbol_coloane:
cmp byte ptr [esi], 0
je simbol_pixel_rosu
mov dword ptr [edi], 0800516h
jmp simbol_pixel_next
simbol_pixel_rosu:
mov dword ptr [edi], 0800516h
simbol_pixel_next:
inc esi
add edi, 4
loop bucla_simbol_coloane
pop ecx
loop bucla_simbol_linii
popa
mov esp, ebp
pop ebp
ret
make_patrat_colorat_rosu endp



make_patrat_colorat_rosu_macro macro patrat_colorat, drawArea, x, y
push y
push x
push drawArea
push patrat_colorat
call make_patrat_colorat_rosu
add esp, 16
endm






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; procedura si macro pt colorare patrat albastru

make_patrat_colorat_albastru proc
push ebp
mov ebp, esp
pusha

mov eax, [ebp+arg1] ; citim simbolul de afisat
lea esi, Patrat_colorat
jmp draw_patrat


draw_patrat:
mov ebx, patrat_colorat_width
mul ebx
mov ebx, patrat_colorat_height
mul ebx
add esi, eax
mov ecx, patrat_colorat_height

bucla_simbol_linii:
mov edi, [ebp+arg2] ; pointer la matricea de pixeli
mov eax, [ebp+arg4] ; pointer la coord y
add eax, patrat_colorat_height
sub eax, ecx
mov ebx, area_width
mul ebx
add eax, [ebp+arg3] ; pointer la coord x
shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
add edi, eax
push ecx
mov ecx, patrat_colorat_width
bucla_simbol_coloane:
cmp byte ptr [esi], 0
je simbol_pixel_albastru
mov dword ptr [edi], 056A5ECh
jmp simbol_pixel_next
simbol_pixel_albastru:
mov dword ptr [edi], 056A5ECh
simbol_pixel_next:
inc esi
add edi, 4
loop bucla_simbol_coloane
pop ecx
loop bucla_simbol_linii
popa
mov esp, ebp
pop ebp
ret
make_patrat_colorat_albastru endp



make_patrat_colorat_albastru_macro macro patrat_colorat, drawArea, x, y
push y
push x
push drawArea
push patrat_colorat
call make_patrat_colorat_albastru
add esp, 16
endm





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; un macro ca sa apelam mai usor desenarea simbolului (canvas)
make_text_macro macro symbol, drawArea, x, y
push y
push x
push drawArea
push symbol
call make_text
add esp, 16
endm






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; macro pt creearea unei linii orizontale

linie_orizontala macro x, y, len, color
;x,y reprezinta coordonatele de unde sa inceapa linia
;len reprezinta lungimea liniei (cati pixeli vrem sa aiba)

local bucla_linii
mov eax, y ;EAX=y
mov ebx, area_width
mul ebx ;EAX=y*area_width
add eax, x ;EAX=y*area_width+x
shl eax, 2 ;EAX=(y*area_width+x)*4
add eax, area
mov ecx, len
bucla_linii:
mov dword ptr[eax], color
add eax, 4 ;ne deplasam la dreapta
;un pixel are 4 bytes
loop bucla_linii
endm





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; macro pt creearea unei linii verticale

linie_verticala macro x, y, len, color
;x,y reprezinta coordonatele de unde sa inceapa linia
;len reprezinta lungimea liniei (cati pixeli vrem sa aiba)

local bucla_linii
mov eax, y ;EAX = y
mov ebx, area_width
mul ebx ;EAX = y * area_width
add eax, x ;EAX = y * area_width + x
shl eax, 2 ;EAX = (y * area_width + x) * 4
add eax, area
mov ecx, len
bucla_linii:
mov dword ptr[eax], color
add eax, area_width * 4 ;ne deplasam in jos
;in jos inseamna ca trebuie sa ne deplasam cu o linie, adica cu area_width*4
loop bucla_linii
endm





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; functia draw (canvas) 

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
push ebp
mov ebp, esp
pusha

mov eax, [ebp+arg1]
cmp eax, 1
jz evt_click
cmp eax, 2
jz evt_timer ; nu s-a efectuat click pe nimic
;mai jos e codul care intializeaza fereastra cu pixeli albi
mov eax, area_width
mov ebx, area_height
mul ebx
shl eax, 2
push eax
push 0
push area
call memset
add esp, 12

call generate_random

jmp afisare_contur






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      EVT CLICK !!!!!!!!!!!!!!!     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


evt_click:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  verificare daca s-a dat click in interiorul patratului



mov eax, [ebp + arg2]    ;aici se afla coordonata x a click_ului
cmp eax, patrat_x        ;comparam coordonata x a click-ului cu coordonata x a patratului mare 
jl final_draw            ;daca este mai mica, inseamna ca nu se afla in aria suprafetei patratului, deci s-a dat click in afara acesuia
cmp eax, patrat_x + patrat_size  
jg final_draw            ; daca este mai mare ca coordonata unde se termina patratul, deci s-a dat click in afara patratului
mov eax, [ebp + arg3]    ;aici se afla coordonata y a click-ului
cmp eax, patrat_y        
jl final_draw
cmp eax, patrat_y + patrat_size
jg final_draw



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  calcul index linie si index coloana matrice din spate, unde s-a dat click 

;Utilizam formulele:

; index_coloana = [ x (click) - coordonata x a patratului mare (140) ] / dimensiune_patrat (90) 
; index_linie = [ y (click) - coordonata y a patratului mare (50) ] / dimensiune_patrat (90) 


mov eax, [ebp + arg2]    ;aici se afla coordonata x a click-ului
sub eax, 140
mov edx, 0
div dimensiune_patrat
mov index_coloana, eax
mov edi, index_coloana ;mutam in registru pt a putea ultiliza in matrix[index][index], in loc de index

mov eax, [ebp + arg3]    ;aici se afla coordonata y a click-ului
sub eax, 50
mov edx, 0
div dimensiune_patrat
mov index_linie, eax
mov esi, index_linie  ;mutam in registru pt a putea ultiliza in matrix[index][index], in loc de index



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; calculam coordonatele patratului in care s-a dat click

;Utilizam formulele: 

; calcul_1 = (patrat_x + index_coloana * 90)*4
; calcul_2 = (patrat_y + index_linie * 90)*4

mov eax, index_coloana
mul dimensiune_patrat 
add eax, patrat_x
;mul valoare4_ajutor_calcul
mov calcul_1, eax

mov eax, index_linie
mul dimensiune_patrat
add eax, patrat_y
;mul valoare4_ajutor_calcul
mov calcul_2, eax




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; verificare in matricea din spate daca s-a dat click pe 1 (vapor), iar daca nu, inseamna ca s-a dat click pe 0 (apa)



cmp matrix[esi*4][edi], 1
je afisare_patrat_rosu   ; daca s-a dat click pe 1, va sari la colorarea patratului rosu 

cmp matrix[esi*4][edi], 0  ; daca s-a dat click pe 0, va sari la colorarea patratului albastru 
je afisare_patrat_albastru

jmp afisare_contur  ; daca nu s-a dat click nici pe 0, nici pe 1, nu vrem sa se intample nimic, deci sarim peste colorare



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; afisare patrat albastru

afisare_patrat_albastru:


mov matrix[esi*4][edi], 3    
; daca s-a dat click pe 0, vrem sa modificam elementul in matrice, deoarece in cazul unui alt click in acelasi patrat, nu vrem sa se recoloreze si
; nu vrem sa se modifice counterul respectiv

add counter_lovituri_ratate, 1    
; daca se coloreaza albastru, inseamna ca NU s-a dat click pe un vapor, deci lovitura este ratata. Crestem numarul de lovituri ratate cu 1



; apelam de 4 ori pt a umple patratul, deoarece am facut 4 patrate (in fisierul inc) de dimensiune 1/4 din patrat
; la primul apel, trimitem ca si parametrii calcul_1, calcul_2
; la urmatorul apel avem nevoie de coordonata din mijlocul patratului (+45)
; nu putem trimite acest calcul ca si parametru la apel, asa ca modificam prin calcule coordonata calcul_2 inainte de apel
; la fel procedam si pentru calcul_1, unde este cazul


make_patrat_colorat_albastru_macro patrat_colorat_desen, area, calcul_1, calcul_2

mov eax, calcul_2      
add eax, 45
mov calcul_2, eax
make_patrat_colorat_albastru_macro patrat_colorat_desen, area, calcul_1, calcul_2

mov eax, calcul_2
sub eax, 45
mov calcul_2, eax
mov eax, calcul_1
add eax, 45
mov calcul_1, eax
make_patrat_colorat_albastru_macro patrat_colorat_desen, area, calcul_1, calcul_2

mov eax, calcul_2
add eax, 45
mov calcul_2, eax
make_patrat_colorat_albastru_macro patrat_colorat_desen, area, calcul_1, calcul_2

jmp afisare_contur  ;sarim la afisare contur, deoarece nu dorim sa se faca si colorarea patratului rosu






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; afisare patrat rosu

afisare_patrat_rosu:

; procedam ca si la colorarea patratului albastru

make_patrat_colorat_rosu_macro patrat_colorat_desen, area, calcul_1, calcul_2

mov eax, calcul_2
add eax, 45
mov calcul_2, eax
make_patrat_colorat_rosu_macro patrat_colorat_desen, area, calcul_1, calcul_2

mov eax, calcul_2
sub eax, 45
mov calcul_2, eax
mov eax, calcul_1
add eax, 45
mov calcul_1, eax
make_patrat_colorat_rosu_macro patrat_colorat_desen, area, calcul_1, calcul_2

mov eax, calcul_2
add eax, 45
mov calcul_2, eax
make_patrat_colorat_rosu_macro patrat_colorat_desen, area, calcul_1, calcul_2


add counter_lovituri_succes, 1    ; daca se coloreaza rosu, inseamna ca s-a dat click pe un vapor, deci crestem nr de lovituri cu succes
sub counter_vapoare_ramase, 1     ; aceeasi situatie, deci scade numarul de vapoare ramase
mov matrix[esi*4][edi], 2




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
evt_timer:
inc counter




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Afisam conturul patratului mare

afisare_contur:

linie_orizontala patrat_x, patrat_y, patrat_size, 0FFFFFFh    ; vrem sa desenam cu alb, iar codul pt alb este 0FFFFFFh
linie_orizontala patrat_x, patrat_y + patrat_size, patrat_size, 0FFFFFFh   
linie_verticala patrat_x, patrat_y, patrat_size, 0FFFFFFh
linie_verticala patrat_x + patrat_size, patrat_y, patrat_size, 0FFFFFFh


; patrat_size = 360,   dimensiune_patrat = 90



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Afisam interiorul patratului mare

afisare_interior:

;vrem sa facem un patrat de dimensiune 4x4 deci avem nevoie de 3 linii orizontale, respectiv verticale pt a imparti

linie_orizontala 140, 50 + 90, 360, 0FFFFFFh
linie_orizontala 140, 50 + 90 + 90, 360, 0FFFFFFh 
linie_orizontala 140, 50 + 90 + 90 + 90, 360, 0FFFFFFh 

linie_verticala 140 + 90, 50, 360, 0FFFFFFh 
linie_verticala 140 + 90 + 90, 50, 360, 0FFFFFFh 
linie_verticala 140 + 90 + 90 +90, 50, 360 , 0FFFFFFh 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Afisam numele proiectului in coltul din stanga sus

make_text_macro 'V', area, 10, 10
make_text_macro 'A', area, 20, 10
make_text_macro 'P', area, 30, 10
make_text_macro 'O', area, 40, 10
make_text_macro 'R', area, 50, 10
make_text_macro 'A', area, 60, 10
make_text_macro 'S', area, 70, 10
make_text_macro 'E', area, 80, 10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Afisam mesajele corespunzatoare cerintei

;numarul de vapoare ramase nedescoperite

make_text_macro 'A', area, 20, 450
make_text_macro 'U', area, 30, 450

make_text_macro 'R', area, 50, 450
make_text_macro 'A', area, 60, 450
make_text_macro 'M', area, 70, 450
make_text_macro 'A', area, 80, 450
make_text_macro 'S', area, 90, 450

make_text_macro 'V', area, 130, 450
make_text_macro 'A', area, 140, 450
make_text_macro 'P', area, 150, 450
make_text_macro 'O', area, 160, 450
make_text_macro 'A', area, 170, 450
make_text_macro 'R', area, 180, 450
make_text_macro 'E', area, 190, 450


;numarul de lovituri cu succes

make_text_macro 'N', area, 20, 500
make_text_macro 'U', area, 30, 500
make_text_macro 'M', area, 40, 500
make_text_macro 'A', area, 50, 500
make_text_macro 'R', area, 60, 500
make_text_macro 'U', area, 70, 500
make_text_macro 'L', area, 80, 500

make_text_macro 'D', area, 100, 500
make_text_macro 'E', area, 110, 500

make_text_macro 'L', area, 130, 500
make_text_macro 'O', area, 140, 500
make_text_macro 'V', area, 150, 500
make_text_macro 'I', area, 160, 500
make_text_macro 'T', area, 170, 500
make_text_macro 'U', area, 180, 500
make_text_macro 'R', area, 190, 500
make_text_macro 'I', area, 200, 500

make_text_macro 'C', area, 220, 500
make_text_macro 'U', area, 230, 500

make_text_macro 'S', area, 250, 500
make_text_macro 'U', area, 260, 500
make_text_macro 'C', area, 270, 500
make_text_macro 'C', area, 280, 500
make_text_macro 'E', area, 290, 500
make_text_macro 'S', area, 300, 500

make_text_macro 'E', area, 320, 500
make_text_macro 'S', area, 330, 500
make_text_macro 'T', area, 340, 500
make_text_macro 'E', area, 350, 500


;numarul de ratari

make_text_macro 'N', area, 20, 550
make_text_macro 'U', area, 30, 550
make_text_macro 'M', area, 40, 550
make_text_macro 'A', area, 50, 550
make_text_macro 'R', area, 60, 550
make_text_macro 'U', area, 70, 550
make_text_macro 'L', area, 80, 550

make_text_macro 'D', area, 100, 550
make_text_macro 'E', area, 110, 550

make_text_macro 'R', area, 130, 550
make_text_macro 'A', area, 140, 550
make_text_macro 'T', area, 150, 550
make_text_macro 'A', area, 160, 550
make_text_macro 'R', area, 170, 550
make_text_macro 'I', area, 180, 550

make_text_macro 'E', area, 200, 550
make_text_macro 'S', area, 210, 550
make_text_macro 'T', area, 220, 550
make_text_macro 'E', area, 230, 550



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Numar de vapoare ramase

verificare_nr_vapoare_ramase :

	cmp counter_vapoare_ramase, 0
	je zero_vapoare_ramase
	cmp counter_vapoare_ramase, 1
	je un_vapor_ramas
	cmp counter_vapoare_ramase, 2
	je doua_vapoare_ramase
	cmp counter_vapoare_ramase, 3
	je trei_vapoare_ramase
	cmp counter_vapoare_ramase, 4
	je patru_vapoare_ramase
	cmp counter_vapoare_ramase, 5
	je cinci_vapoare_ramase
	cmp counter_vapoare_ramase, 6
	je sase_vapoare_ramase
	cmp counter_vapoare_ramase, 7
	je sapte_vapoare_ramase
	cmp counter_vapoare_ramase, 8
	je opt_vapoare_ramase
	cmp counter_vapoare_ramase, 9
	je noua_vapoare_ramase



;afisare nr de vapoare ramase

zero_vapoare_ramase:

	make_text_macro '0', area, 110, 450
	
	make_text_macro 'F', area, 570, 230
	make_text_macro 'E', area, 580, 230
	make_text_macro 'L', area, 590, 230
	make_text_macro 'I', area, 600, 230
	make_text_macro 'C', area, 610, 230        ;Mesaj de succes cand s-au descoperit toate vapoarele
	make_text_macro 'I', area, 620, 230
	make_text_macro 'T', area, 630, 230
	make_text_macro 'A', area, 640, 230
	make_text_macro 'R', area, 650, 230
	make_text_macro 'I', area, 660, 230
	
	jmp verificare_nr_lovituri_cu_succes
	
un_vapor_ramas :
	make_text_macro '1', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
doua_vapoare_ramase :
	make_text_macro '2', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
trei_vapoare_ramase :
	make_text_macro '3', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
patru_vapoare_ramase :
	make_text_macro '4', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
cinci_vapoare_ramase :
	make_text_macro '5', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
sase_vapoare_ramase :
	make_text_macro '6', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
sapte_vapoare_ramase :
	make_text_macro '7', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
opt_vapoare_ramase :
	make_text_macro '8', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
noua_vapoare_ramase :
	make_text_macro '9', area, 110, 450
	jmp verificare_nr_lovituri_cu_succes
	
	
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Verificare numar de lovituri cu succes
	
verificare_nr_lovituri_cu_succes :

	cmp counter_lovituri_succes, 0
	je zero_lovituri_cu_succes
	cmp counter_lovituri_succes, 1
	je o_lovitura_cu_succes
	cmp counter_lovituri_succes, 2
	je doua_lovituri_cu_succes
	cmp counter_lovituri_succes, 3
	je trei_lovituri_cu_succes
	cmp counter_lovituri_succes, 4
	je patru_lovituri_cu_succes
	cmp counter_lovituri_succes, 5
	je cinci_lovituri_cu_succes
	cmp counter_lovituri_succes, 6
	je sase_lovituri_cu_succes
	cmp counter_lovituri_succes, 7
	je sapte_lovituri_cu_succes
	cmp counter_lovituri_succes, 8
	je opt_lovituri_cu_succes
	cmp counter_lovituri_succes, 9
	je noua_lovituri_cu_succes



;afisare nr de lovituri cu succes

zero_lovituri_cu_succes:
	make_text_macro '0', area, 370, 500
	jmp verificare_nr_lovituri_ratate
o_lovitura_cu_succes :
	make_text_macro '1', area, 370, 500
	jmp verificare_nr_lovituri_ratate
doua_lovituri_cu_succes :
	make_text_macro '2', area, 370, 500
	jmp verificare_nr_lovituri_ratate
trei_lovituri_cu_succes :
	make_text_macro '3', area, 370, 500
	jmp verificare_nr_lovituri_ratate
patru_lovituri_cu_succes :
	make_text_macro '4', area, 370, 500
	jmp verificare_nr_lovituri_ratate
cinci_lovituri_cu_succes :
	make_text_macro '5', area, 370, 500
	jmp verificare_nr_lovituri_ratate
sase_lovituri_cu_succes :
	make_text_macro '6', area, 370, 500
	jmp verificare_nr_lovituri_ratate
sapte_lovituri_cu_succes :
	make_text_macro '7', area, 370, 500
	jmp verificare_nr_lovituri_ratate
opt_lovituri_cu_succes :
	make_text_macro '8', area, 370, 500
	jmp verificare_nr_lovituri_ratate
noua_lovituri_cu_succes :
	make_text_macro '9', area, 370, 500
	jmp verificare_nr_lovituri_ratate
	
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Verificare numar de lovituri ratate	
	
verificare_nr_lovituri_ratate :

	cmp counter_lovituri_ratate, 0
	je zero_lovituri_ratate
	cmp counter_lovituri_ratate, 1
	je o_lovitura_ratata
	cmp counter_lovituri_ratate, 2
	je doua_lovituri_ratate
	cmp counter_lovituri_ratate, 3
	je trei_lovituri_ratate
	cmp counter_lovituri_ratate, 4
	je patru_lovituri_ratate
	cmp counter_lovituri_ratate, 5
	je cinci_lovituri_ratate
	cmp counter_lovituri_ratate, 6
	je sase_lovituri_ratate
	cmp counter_lovituri_ratate, 7
	je sapte_lovituri_ratate
	cmp counter_lovituri_ratate, 8
	je opt_lovituri_ratate
	cmp counter_lovituri_ratate, 9
	je noua_lovituri_ratate



;afisare nr de lovituri ratate
zero_lovituri_ratate:
	make_text_macro '0', area, 250, 550
	jmp final_draw
o_lovitura_ratata :
	make_text_macro '1', area, 250, 550
	jmp final_draw
doua_lovituri_ratate :
	make_text_macro '2', area, 250, 550
	jmp final_draw
trei_lovituri_ratate :
	make_text_macro '3', area, 250, 550
	jmp final_draw
patru_lovituri_ratate :
	make_text_macro '4', area, 250, 550
	jmp final_draw
cinci_lovituri_ratate :
	make_text_macro '5', area, 250, 550
	jmp final_draw
sase_lovituri_ratate :
	make_text_macro '6', area, 250, 550
	jmp final_draw
sapte_lovituri_ratate :
	make_text_macro '7', area, 250, 550
	jmp final_draw
opt_lovituri_ratate :
	make_text_macro '8', area, 250, 550
	jmp final_draw
noua_lovituri_ratate :
	make_text_macro '9', area, 250, 550
	jmp final_draw


	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Final draw (canvas)

final_draw:
popa
mov esp, ebp
pop ebp
ret
draw endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Start (canvas)

start:

;alocam memorie pentru zona de desenat
mov eax, area_width
mov ebx, area_height
mul ebx
shl eax, 2
push eax
call malloc
add esp, 4 ;inmultim cu 4 deoarece fiecare pixel din zona de desenat o sa ocute un DWORD, adica 4 bytes
mov area, eax

;apelam functia de desenare a ferestrei
; typedef void (*DrawFunc)(int evt, int x, int y);
; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
push offset draw
push area
push area_height
push area_width
push offset window_title
call BeginDrawing
add esp, 20

;terminarea programului
push 0
call exit
end start