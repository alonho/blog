library ieee;
use ieee.std_logic_1164.all;

entity adder_test is
end adder_test;

architecture arch of adder_test is
  
  component adder is
    port ( 
      x, y: in std_logic;
      sum_0, sum_1: out std_logic
    );
  end component;
  
  signal x, y, sum_0, sum_1: std_logic;
  
  begin
    adder_0: adder port map (
      x => x, y => y, 
      sum_0 => sum_0, sum_1 => sum_1
      );
    
    process
    begin
      x <= '1';
      y <= '1';
      wait for 1 ns;
      assert sum_1 = '1' and sum_0 = '0'
        report "result should be 2" severity error;

      x <= '0';
      y <= '0';
      wait for 1 ns;
      assert sum_1 = '0' and sum_0 = '0'
        report "result should be 0" severity error;

      x <= '1';
      y <= '0';
      wait for 1 ns;
      assert sum_1 = '0' and sum_0 = '1'
        report "result should be 1" severity error;

      x <= '0';
      y <= '1';
      wait for 1 ns;
      assert sum_1 = '0' and sum_0 = '1'
        report "result should be 1" severity error;
            
      wait;
    end process;
end arch;
