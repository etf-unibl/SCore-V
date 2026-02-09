entity reference20 is
end;

library work;

architecture reference20_arch of reference20 is
  component comp
  end component comp;

  for inst : comp use entity work.reference20(Reference20_arch);
begin
  inst: comp;
end;
