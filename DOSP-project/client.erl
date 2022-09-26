-module(client).
-author("harithavannemreddi").
-import(string,[len/1]).
-import(crypto,[hash/2]).
-import(string,[equal/2]).
-export([start/3, start_client/1]).

getProcessCount() -> erlang:system_info(schedulers_online) * 3.

spawn_processes(0, _, _,_) -> ok;

spawn_processes(Count, Node,N, Pid) -> 
    spawn(client, start,[Node,N,Pid]),
    spawn_processes(Count - 1,Node,N, Pid).

start_client(Node) ->
  io:fwrite("ss call invoked..~n"),
  {masterpid,Node} ! {nval,self()},
  receive
        {nval,N,Pid}-> 
           io:format("The n value is ~p",[N])         
    end,
  Count=getProcessCount(),
  spawn_processes(Count,Node,N,Pid).
  
  
start(Node,N,Pid)->
  UfID="48876144",
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
  Status=string:equal(HashedSubString,ZeroString),

if 
    Status == true ->
      io:format("Bitcoin is found and sending message to server from client\n"),
      {masterpid,Node} ! {bitcoin,RandomString,HashString}, 
     % io:format("the string is ~p \n", [String]),
     %io:format("the hashed string is ~p \n", [HashString]),
     %start(Node,N); 
     Pid ! {finished};
    true ->
      start(Node,N,Pid)
    end.


