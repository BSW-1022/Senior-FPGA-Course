library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb is
--  Port ( );
end tb;

architecture Behavioral of tb is
	signal clock : std_logic := '0';
    signal reset :  std_logic := '1'; 
    signal right_player_button : std_logic := '0';
    signal left_player_button : std_logic := '0';
    signal start_button : std_logic := '0';
    signal led_output : std_logic_vector(7 downto 0) := "00000000";
	constant clock_period : time := 10 ns;   
        
    component pingpong Port(clock:in std_logic;
						    reset:in std_logic; 
						    right_player_button:in std_logic;
						    left_player_button:in std_logic;
						    start_button:in std_logic;
						    led_output:out std_logic_vector(7 downto 0)
                           );
    end component; 
begin
	pingpongUUT:pingpong port map(clock=>clock,
                               reset => reset,
                               right_player_button => right_player_button,
                               left_player_button => left_player_button,
                               start_button => start_button,
					           led_output => led_output
                              );

	clock_generate:process  
	begin
        while now< 1000ms loop  
            wait for clock_period / 2;
            clock<=not clock;
        end loop;
        wait;  
	end process clock_generate;
	
	simulation:process
	begin    
        wait for 20ns;
        reset <= '0';
		wait for 100ns;
		start_button <= '1';
		wait for 10ns;
		start_button <= '0';
		wait for 19.87us;
		right_player_button <= '1';
		wait for 10ns;
		right_player_button <= '0';
		--wait for 1.5us;
		--wait for 6.87us;
		--start_button <= '1';
		--wait for 10ns;
		--start_button <= '0';
		--wait for 5us;
		--right_player_button <= '1';
		--wait for 10ns;
		--right_player_button <= '0';
		--wait for 1.5us;
		--left_player_button <= '1';
		--wait for 10ns;
		--left_player_button <= '0';
        wait;              
	end process simulation;	   	

end Behavioral;
