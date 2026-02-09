entity configspec1 is
end;

entity configspec1_sub is
  port (a : bit);
end;

architecture behav of configspec1 is
  component comp
    port (a : bit);
  end component;

  for all: comp use entity work.configspec1_sub;

  signal s : bit;
begin
  c : comp port map (a => s);
end;
