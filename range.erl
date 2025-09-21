-module(range).
-export [seq/2, seq/3, generate/2, wrap/2, next/1].
-export [upto/1, countdown/1, forever/0].
-export [cycle/1, map/2].
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
			throw(range_seq_invalid)   % TODO change this to empty sequence? (so be like lists:seq(), no error)
	end.

% function! Could return anything but N must be integer
generate(Fun, N) when is_function(Fun), is_integer(N) ->
	{generate, Fun, N}.

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
next({generate, Fun, N}) ->
	Next = Fun(N),
	{N, {generate, Fun, Next}};
% wrap, map
next({FunType, Fun, Seq}) when is_function(Fun) andalso is_tuple(Seq) ->
	case Fun(Seq) of
		done -> 
			done;
		{N, Next} ->
			{N, {FunType, Fun, Next}}
	end;
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

forever(Count) when is_integer(Count) ->
	{forever, Count}.


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

% map iterator
map(Fun, Seq0) ->
	Map = fun(Seq) ->
			case range:next(Seq) of
				done -> 
					done;
				{Value, Next} ->
					{Fun(Value), Next}
			end
		  end,
	next_type(map, Map, Seq0).

% if we can name this type (map, filter) then it's operating on a fixed sequence
% OTHERWISE it can be infinite, so just 'wrap'
next_type(Type, Fun, {up, _, _, _} = Seq) ->
	{Type, Fun, Seq};
next_type(Type, Fun, {down, _, _, _} = Seq) ->
	{Type, Fun, Seq};
next_type(_Type, Fun, Seq) ->
	{wrap, Fun, Seq}.

% TODO - just check for wrap, generate, forever...  others will be sequences or wrapped sequences
% ditto for to_list?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List functions

% to_list - if number sequence then convert to list
%           if not (ie. function wrap), then return 'infinity'
%			NB. Need to use take() on an infinite list
to_list({up, _, _, _} = Seq) ->
	to_list1(Seq, []);
to_list({down, _, _, _} = Seq) ->
	to_list1(Seq, []);
to_list({map, _, _} = Seq) ->
	to_list1(Seq, []);
to_list(_) ->
	infinity.

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
% Also must be Number sequence relevant!
% And cope with infinity funcs

% map -> seq
% filter -> seq
% foreach -> iterate -> last_value
% foldl foldr -> result
% take -> list
% from_list ?   (Nope, if got a list then just use lists:* functions)
% member (is N in range)
% length? (cant do on forever/func-gen)
% map_to_list -> list  (will be quicker than map -> to_list)
% filter_to_list -> list  (ditto)
% zip

% not an ITERATOR, just RANGE (of numbers), so don't need everything!

