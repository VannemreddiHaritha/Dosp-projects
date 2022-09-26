
-module(server).
-author("harithavannemreddi").
-import(string,[len/1]).
-import(crypto,[hash/2]).
-import(string,[equal/2]).
-export([find_bitcoin/2,server/2,start_server/0,start_actors/2,term/1]).

find_bitcoin(N,Pid)->
  UfID="48876144;",
  %Generate a random string
  AllowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
  Length = 20,
  String = lists:foldl(fun(_,Acc)->
    [lists:nth(rand:uniform(length(AllowedChars)),AllowedChars)]
    ++Acc
     end, [], lists:seq(1,Length)),
  %Append Random String with UFID
  RandomString=string:concat(UfID,String),
  %Hash the Random string using SHA256
  HashString=io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,RandomString))]),
  %Create a substring from first character to N character
  HashedSubString=string:substr(HashString,1,N),
  % Create a string with N zeros
  ZeroString = string:copies("0",N),
  %compare string with N zeros and Hashed substring of n charcaters
  Status=string:equal(HashedSubString,ZeroString),
  % io:format("master pi is ~p",[masterpid]),

if 
   
    Status == true ->
      io:format("Bitcoin is found and sending message to server\n"),
      %io:format("String ~p and hash ~p \n",[RandomString,HashString]),
      {masterpid,node()} ! {bitcoin,RandomString,HashString},
      Pid ! {finished};    
    true ->
      find_bitcoin(N,Pid) 
    end.
    


server(N,Pid) ->
    
    receive
        {bitcoin,String,Hashedstring} ->
            io:format("the string is ~p \n", [String]),
            io:format("the hashed string is ~p \n", [Hashedstring]),
            server(N,Pid);
        {nval, Client_PID} ->
            io:format("n value is sending to client "),
            Client_PID ! {nval,N,Pid},
            server(N,Pid)
    end.
  
    

start_server() ->

    {_,_} = statistics(runtime),
    {_,_} = statistics(wall_clock),
    Pid = spawn(fun()->term(0) end),
    {ok, N} = io:read("Enter the number: "),        
    register(masterpid, spawn(server,server,[N,Pid])), 
    start_actors(N,Pid).

spawn_processes(0, _, _) -> ok;
spawn_processes(Count, N, Pid) -> 
    spawn(server, find_bitcoin,[N,Pid]),
    spawn_processes(Count - 1, N, Pid).


getProcessCount() -> erlang:system_info(schedulers_online) *2+6.

start_actors(N,Pid)->
    Count = getProcessCount(),
    spawn_processes(Count, N, Pid).

term(CoresDone) ->
    %Cores = erlang:system_info(logical_processors_available), 
    %io:fwrite("TOTAL AVAILABLE CORES ARE ~p",[Cores]),
    P = getProcessCount(),
    if
        CoresDone == P->
                
                {_,T1} = statistics(runtime),
                {_,T2} = statistics(wall_clock),
                CPU_time = T1/ 1000,
                Run_time = T2 / 1000,
                T3 = CPU_time / Run_time,
                io:format("CPU time: ~p seconds\n", [CPU_time]),
                io:format("Real time: ~p seconds\n", [Run_time]),
                io:format("Ratio is ~p \n", [T3]);
            
        true ->
            receive
            {finished} ->
                io:fwrite("Core Computed! Core Count ~p~n",[CoresDone]),
                term(CoresDone+1)
            %Other ->
               % ok
            end
    end.
