entity processlabel2 is
end;

architecture behav of processlabel2 is
begin
  --  Always fails...
  process
  begin
    wait;
  end process;
end;
