entity assocs1 is
end;

architecture behav of assocs1 is
  component comp is
    generic (g1, g2, g3 : natural);
    port (p1, p2 : bit);
  end component;

  signal s1, s2 : bit;
begin
  inst : comp
    generic map (g1 => 1, g2 => 2, g3 => 3)
    port map (p1 => s1, p2 => s2);
end behav;
