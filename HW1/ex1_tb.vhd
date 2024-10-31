library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex1_tb is
--  Port ( );
end ex1_tb;

architecture Behavioral of ex1_tb is
	signal i_clk : STD_LOGIC:='0';
	signal i_rst : STD_LOGIC:='1';
	signal i_upLim:std_logic_vector(3 downto 0):="0110";
	signal i_downLim:std_logic_vector(3 downto 0):="0011";
	signal o_cnt : std_logic_vector(7 downto 0):="00000000";
	constant clock_period : time := 10 ns; 
	
	component ex1 Port (i_clk : in STD_LOGIC;
                        i_rst : in STD_LOGIC;
						i_upLim:in std_logic_vector(3 downto 0);
						i_downLim:in std_logic_vector(3 downto 0);
                        o_cnt : out std_logic_vector(7 downto 0)
					   );
	end component;
begin
	uut:ex1 Port map (i_clk => i_clk,
					  i_rst => i_rst,
					  i_upLim => i_upLim,
					  i_downLim => i_downLim,
					  o_cnt => o_cnt
					 );
					 
	clock_generate:process  
	begin
        while now<5000ms loop  
            wait for clock_period / 2;
            i_clk<=not i_clk;
        end loop;
        wait;  
	end process clock_generate;

	simulation:process
	begin    
        wait for 100ns;
			i_rst <= '0';
        wait;              
	end process simulation;
end Behavioral;
