entity guardedsignal3 is
end;

architecture behav of guardedsignal3 is
  function resolv (v : bit_vector) return bit is
  begin
    return v (v'left);
  end resolv;
  signal s1 : bit;
begin
  b : block
    port (s : out resolv bit bus);
    port map (s => s1);
  begin
  end block;
end;
