entity simpleblock1 is
end;

architecture behav of simpleblock1 is
begin
  b: block
    generic (c : natural := 5);
  begin
  end block;
end;
