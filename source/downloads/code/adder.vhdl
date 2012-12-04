library ieee;
use ieee.std_logic_1164.all;

entity adder is
  port ( 
    x, y: in std_logic;
    sum_0, sum_1: out std_logic
    );
end adder;

architecture arch of adder is 
begin
  sum_0 <= x xor y;
  sum_1 <= x and y;  
end arch;
