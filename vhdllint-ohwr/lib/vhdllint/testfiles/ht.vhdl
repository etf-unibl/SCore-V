entity hello is
end;

architecture behav of hello is
begin
	process
	begin
		assert false report "Hello" severity note;
		wait;
	end process;
end behav;
