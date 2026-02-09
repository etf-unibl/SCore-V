entity simpleblock3 is
end;

architecture behav of simpleblock3 is
  signal s : bit;
begin
  b: block (s = '1')
  begin
  end block;
end;
