function [Items,Freq]=packul(List);
% packul:   return Freq(uency) with which Items occur in ORDERED List.
% [Items,Freq]=packul(List);
% e.g: [Items,Freq]=packul([4 4 4 5 5 6 4 4])
%      yields: Items=[4 5 6 4]
%              Freq =[3 2 1 2]
if isempty(List),
  Items=[];
  Freq=[];
  return;
end
List=List(:)';
Flag=~(~[1 fdiff(List)]);
Items=List(Flag);
T=length(List);
ct=1:T;
Freq=fdiff([ct(Flag) T+1]);
