entity disconnnect1 is
end;

architecture behav of disconnect1 is
  function resolv (v : bit_vector) return bit is
  begin
    return v (v'left);
  end resolv;

  signal s : resolv bit;
  disconnect s : bit after 1 ns;
begin
end;
