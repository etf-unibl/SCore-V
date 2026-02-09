entity guardedsignal1 is
end;

architecture behav of guardedsignal1 is
  function resolv (v : bit_vector) return bit is
  begin
    return v (v'left);
  end resolv;

  signal s : resolv bit bus;
begin
end;
