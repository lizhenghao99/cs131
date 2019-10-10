% check variable size

valid_row([], _).
valid_row([Th|Tt], N) :-
	length(Th, N),
	valid_row(Tt, N).

valid_grid(T, N) :-
	length(T, N),
	valid_row(T, N).

valid_count(C, N) :-
	length(C, 4),
	valid_row(C, N).

valid_tower(N, T, C) :-
	valid_grid(T, N),
	valid_count(C, N).

% list gen
elements_between(List,Min,Max) :-
	maplist(between(Min,Max), List).

all_unique([]).
all_unique([H|T]) :-
	member(H,T),!,fail.
all_unique([_|T]) :-
	all_unique(T).

check_unique([]).
check_unique([H|T]) :-
	all_unique(H),
	check_unique(T).
	
% grid permutation
perm_tower(_, []).
perm_tower(N, [Th|Tt]) :-
	length(Th,N),
	elements_between(Th,1,N),
	all_unique(Th),
	perm_tower(N, Tt).

% count
count([],_,0).
count([Rh|Rt], Max, Result) :-
	Rh > Max,
	count(Rt, Rh, Restresult),
	Result is Restresult + 1.
count([Rh|Rt], Max, Result) :-
	Rh < Max,
	count(Rt, Max, Result).

countrows([],[]).	
countrows([Th|Tt], [Ch|Ct]) :- 
	count(Th, 0, Ch),
	countrows(Tt, Ct).

reverse_grid([],[]).
reverse_grid([Th|Tt],[Rh|Rt]) :-
	reverse(Th,Rh),
	reverse_grid(Tt,Rt).

countreverserows(T,C) :-
	reverse_grid(T,R),
	countrows(R,C).

transpose_grid([],[]).
transpose_grid([[]|_],[]).
transpose_grid([Th|Tt], [Rh|Rt]) :-
	transpose_col([Th|Tt], Rh, Rest),
	transpose_grid(Rest, Rt).

transpose_col([],[],[]).
transpose_col([[H|T]|Rest],[H|Ht],[T|Tt]) :-
	transpose_col(Rest, Ht, Tt).

setN(_,[],[]).
setN(N,[Th|Tt],[Ch|Ct]) :-
	integer(Ch),
	Ch = 1,
	Th = N,
	setN(N,Tt,Ct).
setN(N,[_|Tt],[_|Ct]) :-
	setN(N,Tt,Ct).

setallN(_,[],_).
setallN(N,T,[C1,C2,C3,C4]) :-
	nth(1,T,Tf),
	nth(N,T,Tl),
	setN(N,Tf,C1),
	setN(N,Tl,C2),
	transpose_grid(T,R),
	nth(1,R,Rf),
	nth(N,R,Rl),
	setN(N,Rf,C3),
	setN(N,Rl,C4).

test(N,T,C) :-
	valid_tower(N,T,C),
	setallN(N,T,C).
	
setcounts(T,[C1,C2,C3,C4]) :-
	countrows(T,C3),
	countreverserows(T,C4),
	transpose_grid(T,R),
	countrows(R,C1),
	countreverserows(R,C2).

% plain tower
plain_tower(N, T, counts(C1,C2,C3,C4)) :-
	valid_tower(N, T, [C1,C2,C3,C4]),
	setallN(N, T, [C1,C2,C3,C4]),!,
	perm_tower(N, T),
	transpose_grid(T,R),
	check_unique(R),
	setcounts(T,[C1,C2,C3,C4]).

% -----------
% fd

fd_perm_tower(_, []).
fd_perm_tower(N, [Th|Tt]) :-
    fd_domain(Th,1,N),
	fd_all_different(Th),
    fd_perm_tower(N, Tt).

fd_check_cols([]).
fd_check_cols([Th|Tt]) :-
	fd_all_different(Th),
	fd_check_cols(Tt).

fd_count([],_,0).
fd_count([Rh|Rt], Max, Result) :-
    Rh #> Max,
    fd_count(Rt, Rh, Restresult),
    Result is Restresult + 1.
fd_count([Rh|Rt], Max, Result) :-
    Rh #< Max,
    fd_count(Rt, Max, Result).

fd_countrows([],[]).
fd_countrows([Th|Tt], [Ch|Ct]) :-
    fd_count(Th, 0, Ch),
    fd_countrows(Tt, Ct).

fd_countreverserows(T,C) :-
    reverse_grid(T,R),
    fd_countrows(R,C).

fd_setcounts(T,[C1,C2,C3,C4]) :-
    fd_countrows(T,C3),
    fd_countreverserows(T,C4),
    transpose_grid(T,R),
    fd_countrows(R,C1),
    fd_countreverserows(R,C2).

fd_label([]).
fd_label([Th|Tt]) :-
	fd_labeling(Th),
	fd_label(Tt).
	

tower(N,T,counts(C1,C2,C3,C4)) :-
	valid_tower(N,T,[C1,C2,C3,C4]),
	fd_perm_tower(N,T),
	transpose_grid(T,R),
	fd_check_cols(R),
	fd_setcounts(T,[C1,C2,C3,C4]),
	fd_label(T).

% ------------
% ambiguous

ambiguous(N, C, T1, T2) :-
	tower(N,T1,C),
	tower(N,T2,C),
	T1 \= T2.

% ------------
% speedup

speedup(Result) :-
	statistics(cpu_time,_),
	tower(5,T1,counts(
	[2,1,3,2,2],
	[3,4,1,2,3],
	[2,1,4,2,2],
	[2,3,1,2,3]
	)),
	statistics(cpu_time,[_,Fdtime]),
	statistics(cpu_time,_),
	plain_tower(5,T2,counts(
    [2,1,3,2,2],
    [3,4,1,2,3],
    [2,1,4,2,2],
    [2,3,1,2,3]
    )),
	statistics(cpu_time,[_,Plaintime]),
	T1 = T2,
	Result is Plaintime/Fdtime.
