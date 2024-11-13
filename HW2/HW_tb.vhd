library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity HW_tb is
--  Port ( );
end HW_tb;

architecture Behavioral of HW_tb is
	signal i_clock:STD_LOGIC:='0';
    signal i_reset:STD_LOGIC:='1';
    signal o_led:STD_LOGIC;
	constant clock_period : time := 10ns;
	
	component HW2 Port(i_clock:in STD_LOGIC;
                       i_reset:in STD_LOGIC;
                       o_led:out STD_LOGIC
					  );
	end component;
begin
	uut : HW2 port map(i_clock => i_clock,
					   i_reset => i_reset,
					   o_led => o_led
					   );
					   
	clock_generate:process
	begin
		while now < 3000ms loop
			wait for clock_period / 2;
            i_clock <= not i_clock;
		end loop;
		wait;
	end process clock_generate;
	
	simulation:process
	begin
		wait for 10ns;
		i_reset <= '0';
		wait;
	end process;
end Behavioral;
