entity attrname1 is
end;

architecture behav of attrname1 is
  attribute reserved : boolean;
  signal s : bit;
  attribute reserved of s : signal is True;
  constant c : boolean := s'reserved;
begin
end;
