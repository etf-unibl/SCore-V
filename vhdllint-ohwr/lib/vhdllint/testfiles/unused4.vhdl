entity unused4 is
end;

architecture behav of unused4 is
  function f return natural;
  
  function f return natural is
  begin
    return 5;
  end f;
begin
  assert f > 2;
end;
