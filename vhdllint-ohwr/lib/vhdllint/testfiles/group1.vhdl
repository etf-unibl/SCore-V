entity group1 is
end;

architecture behav of group1 is
  group my_grp is (constant);
  constant c : natural := 5;
  group grp1 : my_group (c);
begin
end;
