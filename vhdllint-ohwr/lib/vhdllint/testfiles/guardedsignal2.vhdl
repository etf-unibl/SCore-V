entity guardedsignal2 is
end;

architecture behav of guardedsignal2 is
  function resolv (v : bit_vector) return bit is
  begin
    return v (v'left);
  end resolv;

  signal s : resolv bit;
begin
end;
