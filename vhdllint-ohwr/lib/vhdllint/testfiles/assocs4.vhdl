entity assocs4 is
end;

architecture behav of assocs4 is
  component comp is
    port (p1, p2 : bit);
  end component;

  signal s1, s2 : bit;
begin
  inst : comp
    port map (s1, p2 => s2);
end behav;
