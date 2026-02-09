entity assocs3 is
end;

architecture behav of assocs3 is
  component comp is
    port (p1, p2 : bit);
  end component;

  signal s1, s2 : bit;
begin
  inst : comp
    port map (p1 => s1, p2 => s2);
end behav;
