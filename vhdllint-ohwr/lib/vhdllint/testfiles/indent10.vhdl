entity indent10 is
end;

architecture behav of indent10 is
  component comp is
  end component;

    for inst: comp use open;
begin
  inst : comp;
end;
