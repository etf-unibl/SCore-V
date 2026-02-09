entity instantiation1 is
end;

architecture behav of instantiation1 is
  signal s1, s2 : bit;

  component comp is
    port (a : bit;
          b : bit);
  end component comp;
begin

  inst: comp
    port map (
      a => s1,
      b => s2);
end behav;
