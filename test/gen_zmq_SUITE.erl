% Copyright 2010-2011, Travelping GmbH <info@travelping.com>

% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the "Software"),
% to deal in the Software without restriction, including without limitation
% the rights to use, copy, modify, merge, publish, distribute, sublicense,
% and/or sell copies of the Software, and to permit persons to whom the
% Software is furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

-module(gen_zmq_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").

reqrep_tcp_test_active(_Config) ->
    basic_tests({127,0,0,1}, 5556, req, rep, active, 3).
reqrep_tcp_test_passive(_Config) ->
    basic_tests({127,0,0,1}, 5557, req, rep, passive, 3).

reqrep_unix_test_active(_Config) ->
    basic_tests([0,"/tmp/reqrep_unix_test_active"], req, rep, active, 3).
reqrep_unix_test_passive(_Config) ->
    basic_tests([0,"/tmp/reqrep_unix_test_passive"], req, rep, passive, 3).

reqrep_tcp_large_active(_Config) ->
    basic_tests({127,0,0,1}, 5556, req, rep, active, 256).
reqrep_tcp_large_passive(_Config) ->
    basic_tests({127,0,0,1}, 5557, req, rep, passive, 256).

req_tcp_bind_close(_Config) ->
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
	ok = gen_zmq:bind(S, tcp, 5555, []),
	gen_zmq:close(S).

req_tcp_connect_close(_Config) ->
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, []),
	gen_zmq:close(S).

req_tcp_connect_fail(_Config) ->
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
    {error,nxdomain} = gen_zmq:connect(S, tcp, "undefined.undefined", 5555, []),
	gen_zmq:close(S).

req_tcp_connect_timeout(_Config) ->
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
	ct:sleep(2000),
	gen_zmq:close(S).

req_tcp_connecting_timeout(_Config) ->
	spawn(fun() ->
				  {ok, L} = gen_tcp:listen(5555,[{active, false}, {packet, raw}, {reuseaddr, true}]),
				  {ok, S1} = gen_tcp:accept(L),
				  ct:sleep(15000),   %% keep socket alive for at least 10sec...
				  gen_tcp:close(S1)
		  end),
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
	ct:sleep(15000),    %% wait for the connection setup timeout
	gen_zmq:close(S).
dealer_tcp_bind_close(_Config) ->
    {ok, S} = gen_zmq:socket([{type, dealer}, {active, false}]),
	ok = gen_zmq:bind(S, tcp, 5555, []),
	gen_zmq:close(S).

dealer_tcp_connect_close(_Config) ->
    {ok, S} = gen_zmq:socket([{type, dealer}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, []),
	gen_zmq:close(S).

dealer_tcp_connect_timeout(_Config) ->
    {ok, S} = gen_zmq:socket([{type, dealer}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
	ct:sleep(2000),
	gen_zmq:close(S).

dealer_tcp_connecting_timeout(_Config) ->
	spawn(fun() ->
				  {ok, L} = gen_tcp:listen(5555,[{active, false}, {packet, raw}, {reuseaddr, true}]),
				  {ok, S1} = gen_tcp:accept(L),
				  ct:sleep(15000),   %% keep socket alive for at least 10sec...
				  gen_tcp:close(S1)
		  end),
    {ok, S} = gen_zmq:socket([{type, dealer}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
	ct:sleep(15000),    %% wait for the connection setup timeout
	gen_zmq:close(S).

req_tcp_connecting_trash(_Config) ->
	Self = self(),
	spawn(fun() ->
				  {ok, L} = gen_tcp:listen(5555,[{active, false}, {packet, raw}, {reuseaddr, true}]),
				  {ok, S1} = gen_tcp:accept(L),
				  T = <<1,16#FF,"TRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASH">>,
				  gen_tcp:send(S1, list_to_binary([T,T,T,T,T])),
				  ct:sleep(500),
				  gen_tcp:close(S1),
				  Self ! done
		  end),
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
	receive 
		done -> ok
	after
        1000 ->
            ct:fail(timeout)
    end,
	gen_zmq:close(S).

rep_tcp_connecting_timeout(_Config) ->
    {ok, S} = gen_zmq:socket([{type, rep}, {active, false}]),
	ok = gen_zmq:bind(S, tcp, 5555, []),
	spawn(fun() ->
				  {ok, L} = gen_tcp:connect({127,0,0,1},5555,[{active, false}, {packet, raw}]),
				  ct:sleep(15000),   %% keep socket alive for at least 10sec...
				  gen_tcp:close(L)
		  end),
	ct:sleep(15000),    %% wait for the connection setup timeout
	gen_zmq:close(S).

rep_tcp_connecting_trash(_Config) ->
	Self = self(),
    {ok, S} = gen_zmq:socket([{type, rep}, {active, false}]),
	ok = gen_zmq:bind(S, tcp, 5555, []),
	spawn(fun() ->
				  {ok, L} = gen_tcp:connect({127,0,0,1},5555,[{active, false}, {packet, raw}]),
				  T = <<1,16#FF,"TRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASHTRASH">>,
				  gen_tcp:send(L, list_to_binary([T,T,T,T,T])),
				  ct:sleep(500),
				  gen_tcp:close(L),
				  Self ! done
		  end),
	receive 
		done -> ok
	after
        1000 ->
            ct:fail(timeout)
    end,
	gen_zmq:close(S).

req_tcp_fragment_send(Socket, Data) ->
	lists:foreach(fun(X) ->	gen_tcp:send(Socket, X), ct:sleep(10) end, [<<X>> || <<X>> <= Data]).

req_tcp_fragment(_Config) ->
	Self = self(),
	spawn(fun() ->
				  {ok, L} = gen_tcp:listen(5555,[binary, {active, false}, {packet, raw}, {reuseaddr, true}, {nodelay, true}]),
				  {ok, S1} = gen_tcp:accept(L),
				  req_tcp_fragment_send(S1, <<16#01, 16#7E>>),
				  gen_tcp:recv(S1, 0),
				  Self ! connected,
				  {ok,<<_:4/bytes,"ZZZ">>} = gen_tcp:recv(S1, 0),
				  req_tcp_fragment_send(S1, <<16#01, 16#7F, 16#06, 16#7E, "Hello">>),
				  gen_tcp:close(S1),
				  Self ! done
		  end),
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, 5555, [{timeout, 1000}]),
	receive 
		connected -> ok
	after
        1000 ->
            ct:fail(timeout)
    end,
	ok = gen_zmq:send(S, [<<"ZZZ">>]),
	{ok, [<<"Hello">>]} = gen_zmq:recv(S),
	gen_zmq:close(S).

create_multi_connect(Type, Active, IP, Port, 0, Acc) ->
	Acc;
create_multi_connect(Type, Active, IP, Port, Cnt, Acc) ->
	{ok, S2} = gen_zmq:socket([{type, Type}, {active, Active}]),
    ok = gen_zmq:connect(S2, tcp, IP, Port, []),
	create_multi_connect(Type, Active, IP, Port, Cnt - 1, [S2|Acc]).

create_bound_pair_multi(Type1, Type2, Cnt2, Mode, IP, Port) ->
    Active = if
        Mode =:= active ->
            true;
        Mode =:= passive ->
            false
    end,
    {ok, S1} = gen_zmq:socket([{type, Type1}, {active, Active}]),
    ok = gen_zmq:bind(S1, tcp, Port, []),

	S2 = create_multi_connect(Type2, Active, IP, Port, Cnt2, []),
	ct:sleep(10),  %% give it a moment to establish all sockets....
    {S1, S2}.

basic_test_dealer_rep(IP, Port, Cnt2, Mode, Size) ->
    {S1, S2} = create_bound_pair_multi(dealer, rep, Cnt2, Mode, IP, Port),
	Msg = list_to_binary(string:chars($X, Size)),

	%% send a message for each client Socket and expect a result on each socket
	lists:foreach(fun(_S) -> ok = gen_zmq:send(S1, [Msg]) end, S2),
	lists:foreach(fun(S) -> {ok, [Msg]} = gen_zmq:recv(S) end, S2),

    ok = gen_zmq:close(S1),
	lists:foreach(fun(S) -> ok = gen_zmq:close(S) end, S2).

basic_test_dealer_req(IP, Port, Cnt2, Mode, Size) ->
    {S1, S2} = create_bound_pair_multi(dealer, req, Cnt2, Mode, IP, Port),
	Msg = list_to_binary(string:chars($X, Size)),

	%% send a message for each client Socket and expect a result on each socket
	lists:foreach(fun(S) -> ok = gen_zmq:send(S, [Msg]) end, S2),
	lists:foreach(fun(_S) -> {ok, [Msg]} = gen_zmq:recv(S1) end, S2),

    ok = gen_zmq:close(S1),
	lists:foreach(fun(S) -> ok = gen_zmq:close(S) end, S2).

basic_tests_dealer(_Config) ->
	basic_test_dealer_req({127,0,0,1}, 5559, 10, passive, 3),
	basic_test_dealer_rep({127,0,0,1}, 5560, 10, passive, 3).

basic_test_router_req(IP, Port, Cnt2, Mode, Size) ->
    {S1, S2} = create_bound_pair_multi(router, req, Cnt2, Mode, IP, Port),
	Msg = list_to_binary(string:chars($X, Size)),

	%% send a message for each client Socket and expect a result on each socket
	lists:foreach(fun(S) -> ok = gen_zmq:send(S, [Msg]) end, S2),
	lists:foreach(fun(_S) ->
						  {ok, {Id, [Msg]}} = gen_zmq:recv(S1),
						  ok = gen_zmq:send(S1, {Id, [Msg]})
				  end, S2),
	lists:foreach(fun(S) -> {ok, [Msg]} = gen_zmq:recv(S) end, S2),

    ok = gen_zmq:close(S1),
	lists:foreach(fun(S) -> ok = gen_zmq:close(S) end, S2).

basic_tests_router(_Config) ->
	basic_test_router_req({127,0,0,1}, 5561, 10, passive, 3).

basic_test_rep_req(IP, Port, Cnt2, Mode, Size) ->
    {S1, S2} = create_bound_pair_multi(rep, req, Cnt2, Mode, IP, Port),
	Msg = list_to_binary(string:chars($X, Size)),

	%% send a message for each client Socket and expect a result on each socket
	lists:foreach(fun(S) -> ok = gen_zmq:send(S, [Msg]) end, S2),
	lists:foreach(fun(_S) ->
						  {ok, [Msg]} = gen_zmq:recv(S1),
						  ok = gen_zmq:send(S1, [Msg])
				  end, S2),
	lists:foreach(fun(S) -> {ok, [Msg]} = gen_zmq:recv(S) end, S2),

    ok = gen_zmq:close(S1),
	lists:foreach(fun(S) -> ok = gen_zmq:close(S) end, S2).

basic_tests_rep_req(_Config) ->
	basic_test_rep_req({127,0,0,1}, 5561, 10, passive, 3).

basic_test_pub_sub(IP, Port, Cnt2, Mode, Size) ->
    {S1, S2} = create_bound_pair_multi(pub, sub, Cnt2, Mode, IP, Port),
	Msg = list_to_binary(string:chars($X, Size)),

	%% send a message for each client and expect a result on each socket
	{error, fsm} = gen_zmq:recv(S1),
	ok = gen_zmq:send(S1, [Msg]),
	lists:foreach(fun(S) -> {ok, [Msg]} = gen_zmq:recv(S) end, S2),
    ok = gen_zmq:close(S1),
	lists:foreach(fun(S) -> ok = gen_zmq:close(S) end, S2).

basic_tests_pub_sub(_Config) ->
	basic_test_pub_sub({127,0,0,1}, 5561, 10, passive, 3).

shutdown_stress_test(_Config) ->
    shutdown_stress_loop(10).

%% version_test() ->
%%     {Major, Minor, Patch} = gen_zmq:version(),
%%     ?assert(is_integer(Major) andalso is_integer(Minor) andalso is_integer(Patch)).

shutdown_stress_loop(0) ->
    ok;
shutdown_stress_loop(N) ->
    {ok, S1} = gen_zmq:socket([{type, rep}, {active, false}]),
	ok = gen_zmq:bind(S1, tcp, 5558 + N, []),
    shutdown_stress_worker_loop(N, 100),
    ok = join_procs(100),
    gen_zmq:close(S1),
    shutdown_stress_loop(N-1).

shutdown_no_blocking_test(_Config) ->
    {ok, S} = gen_zmq:socket([{type, req}, {active, false}]),
    gen_zmq:close(S).

join_procs(0) ->
    ok;
join_procs(N) ->
    receive
        proc_end ->
            join_procs(N-1)
    after
        2000 ->
            throw(stuck)
    end.

shutdown_stress_worker_loop(_P, 0) ->
    ok;
shutdown_stress_worker_loop(P, N) ->
    {ok, S2} = gen_zmq:socket([{type, rep}, {active, false}]),
    spawn(?MODULE, worker, [self(), S2, 5558 + P]),
    shutdown_stress_worker_loop(P, N-1).

worker(Pid, S, Port) ->
    ok = gen_zmq:connect(S, tcp, {127,0,0,1}, Port, []),
    ok = gen_zmq:close(S),
    Pid ! proc_end.

create_bound_pair(Type1, Type2, Mode, IP, Port) ->
    Active = if
        Mode =:= active ->
            true;
        Mode =:= passive ->
            false
    end,
    {ok, S1} = gen_zmq:socket([{type, Type1}, {active, Active}]),
    {ok, S2} = gen_zmq:socket([{type, Type2}, {active, Active}]),
    ok = gen_zmq:bind(S1, tcp, Port, []),
    ok = gen_zmq:connect(S2, tcp, IP, Port, []),
    {S1, S2}.

create_bound_pair(Type1, Type2, Mode, Path) ->
    Active = if
        Mode =:= active ->
            true;
        Mode =:= passive ->
            false
    end,
    {ok, S1} = gen_zmq:socket([{type, Type1}, {active, Active}]),
    {ok, S2} = gen_zmq:socket([{type, Type2}, {active, Active}]),
    ok = gen_zmq:bind(S1, unix, Path, []),
    ok = gen_zmq:connect(S2, unix, Path, []),
    {S1, S2}.

%% assert that message queue is empty....
assert_mbox_empty() ->
	receive
		M -> ct:fail({unexpected, M})
	after
		0 -> ok
	end.

%% assert that top message in the queue is what we think it should be
assert_mbox(Msg) ->
	assert_mbox_match({Msg,[],[ok]}).

assert_mbox_match(MatchSpec) ->
	CompiledMatchSpec = ets:match_spec_compile([MatchSpec]),
    receive
		M -> case ets:match_spec_run([M], CompiledMatchSpec) of
				 [] -> ct:fail({unexpected, M});
				 [Ret] -> Ret
			 end
    after
        1000 ->
            ct:fail(timeout)
    end.

ping_pong({S1, S2}, Msg, active) ->
    ok = gen_zmq:send(S1, [Msg,Msg]),
	assert_mbox({zmq, S2, [Msg,Msg]}),
	assert_mbox_empty(),

    ok = gen_zmq:send(S2, [Msg]),
	assert_mbox({zmq, S1, [Msg]}),
	assert_mbox_empty(),

    ok = gen_zmq:send(S1, [Msg]),
	assert_mbox({zmq, S2, [Msg]}),
	assert_mbox_empty(),

    ok = gen_zmq:send(S2, [Msg]),
 	assert_mbox({zmq, S1, [Msg]}),
	assert_mbox_empty(),
    ok;
    
ping_pong({S1, S2}, Msg, passive) ->
    ok = gen_zmq:send(S1, [Msg]),
    {ok, [Msg]} = gen_zmq:recv(S2),
    ok = gen_zmq:send(S2, [Msg]),
    {ok, [Msg]} = gen_zmq:recv(S1),
    ok = gen_zmq:send(S1, [Msg,Msg]),
    {ok, [Msg,Msg]} = gen_zmq:recv(S2),
    ok.

basic_tests(IP, Port, Type1, Type2, Mode, Size) ->
    {S1, S2} = create_bound_pair(Type1, Type2, Mode, IP, Port),
	Msg = list_to_binary(string:chars($X, Size)),
    ping_pong({S1, S2}, Msg, Mode),
    ok = gen_zmq:close(S1),
    ok = gen_zmq:close(S2).

basic_tests(Path, Type1, Type2, Mode, Size) ->
    {S1, S2} = create_bound_pair(Type1, Type2, Mode, Path),
	Msg = list_to_binary(string:chars($X, Size)),
    ping_pong({S1, S2}, Msg, Mode),
    ok = gen_zmq:close(S1),
    ok = gen_zmq:close(S2).

init_per_suite(Config) ->
	ok = application:start(sasl),
	ok = application:start(gen_listener_tcp),
	ok = application:start(gen_socket),
	ok = application:start(gen_zmq),
	Config.

end_per_suite(Config) ->
	Config.

all() ->
    [
	 reqrep_tcp_test_active, reqrep_tcp_test_passive,
     reqrep_tcp_large_active, reqrep_tcp_large_passive,
     shutdown_no_blocking_test,
	 req_tcp_connect_fail,
     req_tcp_bind_close, req_tcp_connect_close, req_tcp_connect_timeout,
     req_tcp_connecting_timeout, req_tcp_connecting_trash,
     rep_tcp_connecting_timeout, rep_tcp_connecting_trash,
     req_tcp_fragment,
     dealer_tcp_bind_close, dealer_tcp_connect_close, dealer_tcp_connect_timeout,
	 basic_tests_rep_req, basic_tests_dealer, basic_tests_router,
	 basic_tests_pub_sub,
     shutdown_stress_test,
	 reqrep_unix_test_active, reqrep_unix_test_passive
	].
