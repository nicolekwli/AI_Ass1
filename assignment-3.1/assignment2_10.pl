candidate_number(10).


% finds the minimal cost of solving any task of the form (go(p(x,y))), find(o(n),c(n))
% find path using energy available (part 1)
% find path considering more stuff (part3/4)

% for example solve_task(+go(Pos), -Cost).
% fail when task not feasible/ no energy
solve_task(Task,Cost):-
  my_agent(Agent),
  query_world( agent_current_position, [Agent,P] ),

  ClosedList = [p(1,1)],
  
  % proceed to find the shortest path
  solve_task_bt(Task,[c(0,0,P),P], ClosedList, 0,R,Cost,_NewPos),!,
  reverse(R,[_Init|Path]),

  % This performs the path found 
  query_world( agent_do_moves, [Agent,Path] ).


%%%%%%%%%% Useful predicates %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% solve_task_bt(+Task,+Current,+Depth,-RPath,-Cost,-NewPos)
% Current is of the form [c(F,P)|RPath]; 
%    RPath is a list of positions denoting the current path (in reverse) 
%       from the start position (at the end) to the current position P (at the head)
%    F is the cost of getting from the start position to P
% Depth is the current search depth

solve_task_bt(Task,Current, ClosedList, Depth,RPath,[cost(Cost),depth(Depth)],NewPos) :-
  achieved(Task,Current,RPath,Cost,NewPos).


% A* algorithm
solve_task_bt(Task,Current, ClosedList, D,RR,Cost,NewPos) :-

  Current = [c(F, G, P) | RPath],
  RPath = [RPath_h| RPath_t],

  % IF IT IS A GO -----!! This needs changing so it accomodates find() as well !!----- 
  Task = go(Final),

  ClosedList = [p(Pos_cx, Pos_cy) | Pos_ct],

  % Gets a list of possible next positions using setof involving search
  % setof(+Template, +Goal, -Set) 
    % binds Set to the list of all instances of Template satisfying the goal Goal
  setof(c(NextPos, Next_H), search(P, Final, NextPos, Next_H, 1), PossChildren), 

  % if this breaks we need to backtrack to the move that led to the deadend
    % use condition  
  get_best_next_move(PossChildren, RPath, Final, ClosedList, 99, Move),
  
  D1 is D+1,
  G1 is G + 1,
  
  get_head(Move, NewMove),
  NewMove = c(MovePos, MoveG),
 
  % when its a deadend
  ( MoveG == 99 -> write('NEED TO BACKTRACK TO LAST POS'),
    RPath_t = [RPath_th | RPath_tt],
    map_distance(RPath_h, Final, H1), 
    F1 is G1 + H1, 
    NextMovePos = RPath_th, 
    RPathNew = RPath_tt,
    write('\nDONEDONEDONE\n'),
    ClosedListNew = [P|ClosedList]                                                            
    ;map_distance(MovePos, Final, H1), F1 is G1 + H1, NextMovePos = MovePos, RPathNew = RPath, ClosedListNew = ClosedList
  ),
  
  % and we have found the next position for the agent to move to
  solve_task_bt(Task,[c(F1, G1, NextMovePos), NextMovePos | RPathNew], ClosedListNew, D1,RR,Cost,NewPos).  % backtrack search


%% achieved - detects when the specified task has been solved
achieved(go(Exit),Current,RPath,Cost,NewPos) :-
  Current = [c(F,G,NewPos)|RPath],
  Cost is G,
  ( Exit=none -> true
  ; otherwise -> RPath = [Exit|_]
  ).

achieved(find(O),Current,RPath,Cost,NewPos) :-
  Current = [c(F,G,NewPos)|RPath],
  Cost is G,
  ( O=none    -> true
  ; otherwise -> RPath = [Last|_],map_adjacent(Last,_,O)
  ).


% this is called by setof
search(F, Final, N, H, 1) :-
  map_adjacent(F,N,empty),
  map_distance(N, Final, H).


% This is the main bit that gets the best aka lowest cost next move 
get_best_next_move([], RPath, Final, ClosedList, BestH, Move).


get_best_next_move([c(Pos, Pos_h) | []], RPath, Final, [], BestH, Move) :-
  (\+check_if_in_path(Pos, ClosedList) -> write('IS IN CLOSED LIST'), Move = [c(Pos, 99)]
    ;( \+check_if_in_path(Pos, RPath) -> write('IT IS IN PATH'), Move = [c(Pos, 99)]
      ;( \+check_if_dead_end(Pos) -> write('This is a dead end.'), Move = [c(p(0,0), 99)]
        ;( Pos == Final -> write('Goal found'), Move = [c(Pos, 0)]
          ;( Pos_h < BestH -> write('G is less than1'), Move = [c(Pos, Pos_h)]
          )
        )
      )
    )
  ).

get_best_next_move([c(Pos, Pos_h) | []], RPath, Final, ClosedList, BestH, Move) :-
  (\+check_if_in_path(Pos, ClosedList) -> write('IS IN CLOSED LIST'), Move = [c(Pos, 99)]
    ;( \+check_if_in_path(Pos, RPath) -> write('IT IS IN PATH'), Move = [c(Pos, 99)] 
      ;( \+check_if_dead_end(Pos) -> write('This is a dead end.'), Move = [c(p(0,0), 99)]
        ;( Pos == Final -> write('Goal found'), Move = [c(Pos, 0)]
          ;( Pos_h < BestH -> write('G is less than1'), Move = [c(Pos, Pos_h)]
          )
        )
      )
    )
  ).

% get_best_next_move([c(Pos, Pos_g)|Children], RPath, Final, BestG, Move) :-
get_best_next_move([c(Pos, Pos_h)|Children], RPath, Final, ClosedList, BestH, Move) :-
  %PossChildren = [c(Pos, Pos_g)|Children],
  get_best_next_move(Children, RPath, Final, ClosedList, BestH, Move_t),

  Child = c(Pos, Pos_h),
  Move_t = [c(Pos_t, Pos_th) | Move_ts],

  % \not +provable,
  % \+memberchk(Child, RPath),
  % write('its not in path'),

  % Check if it is the end
      % chek if child has more childs -> if not ignore
      % check if child is in the closed list(lets say RPath)  -> if is, ignore
      % check if child is in the open list -> if not then add
        % if it is, check g to destination, if bterr change ,value in open list
  (\+check_if_in_path(Pos, ClosedList) -> write('IS IN CLOSED LIST'), Move = Move_t
    ;( \+check_if_in_path(Pos, RPath) -> write('IT IS IN PATH'), Move = Move_t
      ;( \+check_if_dead_end(Pos) -> write('This is a dead end.'), Move = [Move_t]
        ;( Pos == Final -> write('Goal found'), Move = [c(Pos, 0)]
          ;( Pos_h < Pos_th -> write('G is less than2'), Move = [Child|Move_t]
            ; write('THIS IS THE POS IT BREAK'), write(Pos), Move = Move_t
          )
        )
      )
    )
  ).

get_head([X], X).
get_head([X|_], X).


check_if_in_path(Pos, RPath) :-
  \+memberchk(Pos, RPath).

% should maybe include oracles and shits
check_if_dead_end(P) :-
  % what is this case?
  setof(Child, map_adjacent(P, Child, empty), Poss).
  
  %case- if not enough energy to do a task, fail