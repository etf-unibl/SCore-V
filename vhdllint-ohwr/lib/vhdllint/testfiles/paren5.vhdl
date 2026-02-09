entity paren5 is
end;

architecture behav of paren5 is
  function f return natural is
  begin
    return (4);
  end f;
begin
end behav;
