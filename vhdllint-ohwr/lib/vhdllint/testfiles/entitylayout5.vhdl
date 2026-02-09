entity entitylayout1 is
  generic (
    a, b : integer := 3;
    c    : integer := 2
  );
  port (
    i1 : in  bit := '0';
    o1 : out bit
  );
end entitylayout1;
