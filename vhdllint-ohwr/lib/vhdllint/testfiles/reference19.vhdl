entity reference19 is
end;

library work;

architecture reference19_arch of reference19 is
  component comp
  end component comp;

  for inst : comp use entity work.reference19(foobar);
begin
  inst: comp;
end;
