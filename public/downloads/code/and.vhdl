library ieee;
use ieee.std_logic_1164.all;	

entity and_entity is
  port(	
    x, y: in std_logic;
    result: out std_logic
    );
end and_entity;
  
architecture arch of and_entity is
begin  
  result <= x and y;
end arch;
