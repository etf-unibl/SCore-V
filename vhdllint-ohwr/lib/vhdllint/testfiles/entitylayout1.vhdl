entity entitylayout1 is
  generic (
    a : bit     := '0';
    b : integer := 2
  );
  port (
    i1 : in  bit := '0';
    o1 : out bit
  );
end entitylayout1;
