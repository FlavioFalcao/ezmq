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

-module(gen_zmq_tcp_socket).
-behaviour(gen_listener_tcp).

-include("gen_zmq_debug.hrl").

-define(TCP_PORT, 5555).
-define(TCP_OPTS, [binary, inet,
                   {ip,           {127,0,0,1}},
                   {active,       false},
				   {send_timeout, 5000},
                   {backlog,      10},
                   {nodelay,      true},
                   {packet,       raw},
                   {reuseaddr,    true}]).

%% --------------------------------------------------------------------
%% External exports
-export([start/3, start_link/3]).

%% gen_listener_tcp callbacks
-export([init/1, handle_accept/2, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%-record(state, {}).

-ifdef(debug).
-define(SERVER_OPTS,{debug,[trace]}).
-else.
-define(SERVER_OPTS,).
-endif.

%% ====================================================================
%% External functions
%% ====================================================================

%% @doc Start the server.
start(Identity, Port, Opts) ->
    gen_listener_tcp:start(?MODULE, [self(), Identity, Port, Opts], [?SERVER_OPTS]).

start_link(Identity, Port, Opts) ->
    gen_listener_tcp:start_link(?MODULE, [self(), Identity, Port, Opts], [?SERVER_OPTS]).

init([MqSocket, Identity, Port, Opts]) ->
    {ok, {Port, Opts}, {MqSocket, Identity}}.

handle_accept(Sock, State = {MqSocket, Identity}) ->
	case gen_zmq_link:start_connection() of
		{ok, Pid} ->
			gen_zmq_link:accept(MqSocket, Identity, Pid, Sock);
		_ ->
			error_logger:error_report([{event, accept_failed}]),
			gen_tcp:close(Sock)
	end,
    {noreply, State}.

handle_call(Request, _From, State) ->
    {reply, {illegal_request, Request}, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, _State) ->
	?DEBUG("gen_zmq_tcp_socket terminate on ~p", [Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
