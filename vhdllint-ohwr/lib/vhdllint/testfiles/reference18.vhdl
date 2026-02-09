entity reference18 is
end;

library work;

architecture reference18_arch of reference18 is
  component comp
  end component comp;

  for inst : comp use entity work.reference18(reference18_arch);
begin
  inst: comp;
end;
