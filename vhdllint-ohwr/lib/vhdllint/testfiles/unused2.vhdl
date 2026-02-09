entity unused2 is
  generic (len : natural := 5);
  port (dat : bit_vector(len - 1 downto 0));
end;

architecture behav of unused2 is
begin
  assert dat = (dat'range => '0');
end;
