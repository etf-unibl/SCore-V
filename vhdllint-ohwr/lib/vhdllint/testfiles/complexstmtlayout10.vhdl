entity complexstmtlayout10 is
end;

architecture behav of complexstmtlayout10 is
begin
  g1: if True
        generate
    assert false;
  end generate;
end behav;
