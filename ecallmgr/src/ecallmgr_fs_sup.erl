%%%-------------------------------------------------------------------
%%% @copyright (C) 2012, VoIP, INC
%%% @doc
%%%
%%% @end
%%% @contributors
%%%-------------------------------------------------------------------
-module(ecallmgr_fs_sup).

-behaviour(supervisor).

-include_lib("ecallmgr/src/ecallmgr.hrl").

-define(SERVER, ?MODULE).

-export([start_link/0]).
-export([add_node/2]).
-export([remove_node/1]).
-export([init/1]).

-define(CHILD(Name, Type), fun(N, cache) -> {N, {wh_cache, start_link, [N]}, permanent, 5000, worker, [wh_cache]};
                              (N, T) -> {N, {N, start_link, []}, permanent, 5000, T, [N]} end(Name, Type)).
-define(NODE(Name, Args), {Name, {ecallmgr_fs_node_sup, start_link, Args}, transient, 5000, supervisor, [ecallmgr_fs_node_sup]}).
-define(CHILDREN, [{ecallmgr_fs_nodes, worker}, {ecallmgr_fs_pinger_sup, supervisor}]).

%% ===================================================================
%% API functions
%% ===================================================================

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Starts the supervisor
%% @end
%%--------------------------------------------------------------------
-spec start_link/0 :: () -> startlink_ret().
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

-spec add_node/2 :: (atom(), proplist()) -> startlink_ret().
add_node(Node, Options) ->
    supervisor:start_child(?SERVER, ?NODE(Node, [Node, Options])).

-spec remove_node/1 :: (atom()) -> 'ok' | {'error', 'running' | 'not_found' | 'simple_one_for_one'}.
remove_node(Node) ->
    supervisor:terminate_child(?SERVER, Node),
    supervisor:delete_child(?SERVER, Node).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%% @end
%%--------------------------------------------------------------------
-spec init(list()) -> sup_init_ret().
init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 5,
    MaxSecondsBetweenRestarts = 10,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Children = [?CHILD(Name, Type) || {Name, Type} <- ?CHILDREN],

    {ok, {SupFlags, Children}}.
