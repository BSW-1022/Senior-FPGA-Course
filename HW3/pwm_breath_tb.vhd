library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwm_breath_tb is
--  Port ( );
end pwm_breath_tb;

architecture Behavioral of pwm_breath_tb is
    signal i_clk : STD_LOGIC := '0';
    signal i_rst : STD_LOGIC := '0';
    signal i_sw_up : STD_LOGIC := '0';
    signal i_sw_dn : STD_LOGIC := '0';         
    signal pwm :STD_LOGIC;
    constant clock_period : time := 10 ns; 
    
    component pwm_breath Port (i_clk : in STD_LOGIC;
                               i_rst : in STD_LOGIC;
                               i_sw_up : in STD_LOGIC;
                               i_sw_dn : in STD_LOGIC;           
                               pwm : out STD_LOGIC
					   );
	end component;
begin
    uut:pwm_breath Port map (i_clk => i_clk,
					  i_rst => i_rst,
					  i_sw_up => i_sw_up,
					  i_sw_dn => i_sw_dn,
					  pwm => pwm
					 );
					 
    clock_generate:process  
	begin
        while now<5000ms loop  
            wait for clock_period / 2;
            i_clk<=not i_clk;
        end loop;
        wait;  
	end process clock_generate;
------------------- test bench ------------
   -- Stimulus process
   stim_proc: process
   begin 
      -- hold reset state for 100 ns.
      i_rst <= '0';
      i_sw_up <= '0';
      i_sw_dn <= '0';
      wait for 100 ns; 
      i_rst <= '1';
      wait for clock_period *1024 *256;
      -- insert stimulus here 
      wait;
   end process;
end Behavioral;
