%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ.
%%
%%   The Initial Developers of the Original Code are LShift Ltd,
%%   Cohesive Financial Technologies LLC, and Rabbit Technologies Ltd.
%%
%%   Portions created before 22-Nov-2008 00:00:00 GMT by LShift Ltd,
%%   Cohesive Financial Technologies LLC, or Rabbit Technologies Ltd
%%   are Copyright (C) 2007-2008 LShift Ltd, Cohesive Financial
%%   Technologies LLC, and Rabbit Technologies Ltd.
%%
%%   Portions created by LShift Ltd are Copyright (C) 2007-2010 LShift
%%   Ltd. Portions created by Cohesive Financial Technologies LLC are
%%   Copyright (C) 2007-2010 Cohesive Financial Technologies
%%   LLC. Portions created by Rabbit Technologies Ltd are Copyright
%%   (C) 2007-2010 Rabbit Technologies Ltd.
%%
%%   All Rights Reserved.
%%
%%   Contributor(s): ______________________________________.
%%

-module(rabbit_msg_store_ets_index).

-behaviour(rabbit_msg_store_index).

-export([new/1, recover/1,
         lookup/2, insert/2, update/2, update_fields/3, delete/2,
         delete_by_file/2, terminate/1]).

-define(MSG_LOC_NAME, rabbit_msg_store_ets_index).
-define(FILENAME, "msg_store_index.ets").

-include("rabbit_msg_store_index.hrl").

-record(state, { table, dir }).

new(Dir) ->
    file:delete(filename:join(Dir, ?FILENAME)),
    Tid = ets:new(?MSG_LOC_NAME, [set, public, {keypos, #msg_location.guid}]),
    #state { table = Tid, dir = Dir }.

recover(Dir) ->
    Path = filename:join(Dir, ?FILENAME),
    case ets:file2tab(Path) of
        {ok, Tid}  -> file:delete(Path),
                      {ok, #state { table = Tid, dir = Dir }};
        Error      -> Error
    end.

lookup(Key, State) ->
    case ets:lookup(State #state.table, Key) of
        []      -> not_found;
        [Entry] -> Entry
    end.

insert(Obj, State) ->
    true = ets:insert_new(State #state.table, Obj),
    ok.

update(Obj, State) ->
    true = ets:insert(State #state.table, Obj),
    ok.

update_fields(Key, Updates, State) ->
    true = ets:update_element(State #state.table, Key, Updates),
    ok.

delete(Key, State) ->
    true = ets:delete(State #state.table, Key),
    ok.

delete_by_file(File, State) ->
    MatchHead = #msg_location { file = File, _ = '_' },
    ets:select_delete(State #state.table, [{MatchHead, [], [true]}]),
    ok.

terminate(#state { table = MsgLocations, dir = Dir }) ->
    ok = ets:tab2file(MsgLocations, filename:join(Dir, ?FILENAME),
                      [{extended_info, [object_count]}]),
    ets:delete(MsgLocations).
