-module(range_tests).
-include_lib("eunit/include/eunit.hrl").

% Some of these tests contain internal details.  Keep for now but may remove

seq_invalid_test() ->
    ?assertThrow(range_seq_invalid, range:seq(4,4)),
    ?assertThrow(range_seq_invalid, range:seq(4,3)),
    ?assertThrow(range_seq_invalid, range:seq(3,4,-1)).

seq_up_test() ->
    Seq = range:seq(1,3),
    {1, N1} = range:next(Seq),
    ?assertEqual({up, 2, 3, 1}, N1),
    {2, N2} = range:next(N1),
    ?assertEqual({up, 3, 3, 1}, N2),
    {3, N3} = range:next(N2),
    ?assertEqual({up, 4, 3, 1}, N3),
    ?assertEqual(done, range:next(N3)).

seq_down_test() ->
    Seq = range:seq(1, -2, -1),
    {1, N1} = range:next(Seq),
    {0, N2} = range:next(N1),
    {-1, N3} = range:next(N2),
    {-2, N4} = range:next(N3),
    ?assertEqual({down, -3, -2, -1}, N4),
    ?assertEqual(done, range:next(N4)).

seq_step_test() ->
    Seq = range:seq(0, 4, 2),
    {0, N1} = range:next(Seq),
    {2, N2} = range:next(N1),
    {4, N3} = range:next(N2),
    ?assertEqual({up, 6, 4, 2}, N3),
    ?assertEqual(done, range:next(N3)).

seq_step_over_test() ->
    Seq = range:seq(0, 5, 2),
    {0, N1} = range:next(Seq),
    {2, N2} = range:next(N1),
    {4, N3} = range:next(N2),
    ?assertEqual(done, range:next(N3)).

seq_step_under_test() ->
    Seq = range:seq(0, 3, 2),
    {0, N1} = range:next(Seq),
    {2, N2} = range:next(N1),
    ?assertEqual(done, range:next(N2)).

seq_step_float_up_test() ->
    Seq = range:seq(1, 1.4, 0.2),
    {1, N1} = range:next(Seq),            % remember we started this is integer 1
    {1.2, N2} = range:next(N1),
    {1.4, N3} = range:next(N2),
    ?assertEqual(done, range:next(N3)).

seq_step_float_down_test() ->
    Seq = range:seq(1.4, 1, -0.2),
    {1.4, N1} = range:next(Seq),
    {1.2, N2} = range:next(N1),
    {1.0, N3} = range:next(N2),           % notice this is now float
    ?assertEqual(done, range:next(N3)).

seq_next_silly_test() ->
    ?assertThrow(range_seq_exhausted, range:next(done)).

upto_test() ->
    Seq = range:upto(2),
    {0, N1} = range:next(Seq),
    {1, N2} = range:next(N1),
    ?assertEqual(done, range:next(N2)).

countdown_test() ->
    Seq = range:countdown(2),
    {2, N1} = range:next(Seq),
    {1, N2} = range:next(N1),
    ?assertEqual(done, range:next(N2)).

forever_test() ->
    Seq = range:forever(),
    {1, N1} = range:next(Seq),
    {2, N2} = range:next(N1),
    ?assertEqual({3, {forever, 4}}, range:next(N2)).

cycle_test() ->
    Seq = range:seq(1,3),
    Cycle = range:cycle(Seq),
    {1, A1} = range:next(Cycle),
    {2, A2} = range:next(A1),
    {3, A3} = range:next(A2),
    {1, A4} = range:next(A3),
    {2, A5} = range:next(A4),
    {3, _} = range:next(A5).

cycle_invalid_test() ->
    Seq = range:forever(),
    ?assertThrow(range_cycle_invalid, range:cycle(Seq)).

    

% how do you use iterator in List comp?   You can't, must be a list!!
