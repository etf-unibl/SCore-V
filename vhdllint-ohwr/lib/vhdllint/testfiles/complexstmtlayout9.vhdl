entity complexstmtlayout9 is
end;

architecture behav of complexstmtlayout9 is
begin
  g1: for i in 1 to 7
        generate
    assert false;
  end generate;
end behav;
