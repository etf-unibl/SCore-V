entity entitylayout7 is
  generic (
    a : bit     := '0';
    b : integer := 2
  );
  port (
    i1 : in  bit_vector(3 downto 0) := x"0";
    o1 : out bit
  );
end;
