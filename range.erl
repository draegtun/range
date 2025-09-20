-module(range).
-export [seq/2, seq/3, generate/2, wrap/2, next/1].
-export [upto/1, countdown/1, forever/0, forever/1, repeat/1].
-export [cycle/1].
-export [to_list/1].


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Core seq/next funcs

seq(From, To) ->
	seq(From, To, 1).

% seq can be integers or floats
seq(From, To, Step) when is_number(From), is_number(To), is_number(Step) ->
	if 
		Step > 0, From < To ->
			{up, From, To, Step};
		Step < 0, From > To ->
			{down, From, To, Step};
		true ->
			throw(range_seq_invalid)
	end.

% function! Could return anything but N must be integer
generate(Fun, N) when is_function(Fun), is_integer(N) ->
	{function, Fun, N}.

% wrap! Used to wrap functions with Seq tuple
wrap(Fun, Seq) when is_function(Fun), is_tuple(Seq) ->
	{wrap, Fun, Seq}.

% next iterator
next({up, From, To, Step}) when From =< To ->
	Next = {up, From+Step, To, Step},
	{From, Next};
next({down, From, To, Step}) when From >= To ->
	Next = {down, From+Step, To, Step},
	{From, Next};
next({forever, N}) ->
	Next = {forever, N+1},
	{N, Next};
next({repeat, Fun} = Next) when is_function(Fun) ->
	{Fun(), Next};
next({repeat, It} = Next) ->
	{It, Next};
next({function, Fun, N}) ->
	Next = Fun(N),
	{N, {function, Fun, Next}};
next({wrap, Fun, Seq}) ->
	{N, Next} = Fun(Seq),
	{N, {wrap, Fun, Next}};
next(done) ->
	% shouldn't happen but if someone does send 'done' then throw this error!
	throw(range_seq_exhausted);
next(_) ->
	done.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% seq/next nicety (seq builder) funcs 
%% NB. These just return Seq{} because we cannot provide invalid Seq
%%     Haven't put in fallback (throw error) clauses for these

% upto(10) -> 0..9
upto(N) when is_integer(N) andalso N > 0 ->
	seq(0, N-1).

% countdown(10) -> 10..1
countdown(N) when is_integer(N) andalso N > 0 ->
	seq(N, 1, -1).

% forever() -> 1..infinity
forever() ->
	forever(1).

forever(From) when is_integer(From) ->
	{forever, From}.

% repeat(something) will just keep repeating 'something'
% Unlike forever, it's not building an integer, so lighter if really forever :)
% and if you provide a Fun/0 then it will run it each time
repeat(It) ->
	{repeat, It}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wrapped funcs

% cycle a (fixed) Seq
cycle({up, _, _, _} = Seq) ->
	cycle2(Seq);
cycle({down, _, _, _} = Seq) ->
	cycle2(Seq);
cycle(_) ->
	throw(range_cycle_invalid).

cycle2(Seq0) ->
	Fun = fun(Seq) ->
		case range:next(Seq) of
			done -> 
				range:next(Seq0);  	%reset, ie. recycle
			Range ->
				Range				% continue with current Seq
		end
	end,
	wrap(Fun, Seq0).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List functions

% to_list - if number sequence then convert to list
%           if not (ie. function wrap), then return 'infinite'
to_list({up, _, _, _} = Seq) ->
	to_list1(Seq, []);
to_list({down, _, _, _} = Seq) ->
	to_list1(Seq, []);
to_list(_) ->
	infinite.

to_list1(Seq, Acc) ->
	case range:next(Seq) of
		done ->
			lists:reverse(Acc);
		{Value, Next} ->
			to_list1(Next, [Value | Acc])
	end.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% What things from lists: module??
% Whats applicable?  whats important??  don't want too much flaff/fluff :)

% cycle / filter
% map / foreach
% length? (cant do on forever/func-gen)
% foldl foldr
% [DONE] forever (from 1)
% function generate?  (means you could return otherthings to numbers?)
% take? (is this needed for working with forever and func-gen?)
% from_list ?   (Nope, if got a list then just use lists:* functions
% to_list
% member (is N in range)

% not an ITERATOR, just RANGE (of numbers), so don't need everything!

