package unused3 is
  function f return natural;
end;

package body unused3 is
  function f return natural is
  begin
    return 5;
  end f;

  constant c : natural := f;
end;
