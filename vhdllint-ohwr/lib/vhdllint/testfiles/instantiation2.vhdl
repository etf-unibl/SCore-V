entity instantiation2 is
end;

architecture behav of instantiation2 is
  signal s1, s2 : bit;

  component comp is
    port (a : bit;
          b : bit);
  end component comp;
begin

  inst: comp
    port map (s1, b => s2);
end behav;
