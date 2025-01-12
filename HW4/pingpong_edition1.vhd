--PingPong Edition1 is constant velcoity
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

entity pingpong is
	Port (clock:in std_logic;
          reset:in std_logic; 
          right_player_button:in std_logic;
          left_player_button:in std_logic;
          start_button:in std_logic;
          led_output:out std_logic_vector(7 downto 0)
		  );
end pingpong;

architecture Behavioral of pingpong is
	signal clk_div_cnt : std_logic_vector(26 downto 0):= (others => '0'); --除頻counter
    signal to_shift_clk : std_logic; --處理輸出的時脈
    signal shift_reg : std_logic_vector(7 downto 0):= (others => '0');--乒乓位移暫存器 
    signal right_score : std_logic_vector(3 downto 0):= (others => '0');--右邊分數暫存器 
    signal left_score : std_logic_vector(3 downto 0):= (others => '0');--左邊分數暫存器 
    signal rsToLwin : std_logic:='0';--右邊得分旗號
    signal lsToRwin : std_logic:='0';--左邊得分旗號
	signal ballComing : std_logic:='0';--發球，設置 LED 10000000、00000001用
    --以下乒乓FSM參數
    type state_type is (init,zero_and_zero,r_shift,l_shift,rwin,lwin);
    signal state:state_type:=init; 
begin
	div_clk:process(clock,reset)
    begin
        if reset='1' then
            clk_div_cnt<= (others=>'0');
        elsif clock='1' and clock'event then
            clk_div_cnt <= clk_div_cnt + 1;
        end if;
    end process div_clk;
	to_shift_clk <= clk_div_cnt(23);
	
	FSM_state_process: process(clock, reset)
    begin
        if reset = '1' then
            state <= init;
        elsif rising_edge(clock) then
            case state is
                when init => 
                    state <= zero_and_zero;  
                when zero_and_zero | lwin =>         
                    if start_button='1' then
                        state <= r_shift;
                    else
                        null;
                    end if;
				when rwin => 
					if start_button='1' then
                        state <= l_shift;
                    else
                        null;
                    end if;
                when r_shift =>              
                    if right_player_button = '1' then
						if shift_reg = "00000001" then
							state <= l_shift;
						else
							state <= lwin;
						end if;
					else 
						if shift_reg = "00000000" and rsToLwin = '1' then 
							state <= lwin;
						else
							null;
						end if;
					end if; 
                when l_shift =>
                    if left_player_button = '1' then 
						if shift_reg = "10000000" then
							state <= r_shift;
						else
							state <= rwin;
						end if;
					else 
						if shift_reg = "00000000" and lsToRwin = '1' then 
							state <= rwin;
						else
							null;
						end if;
					end if;
                when others =>
                    state <= init;
            end case;
        end if;
    end process FSM_state_process;
    
    ledProcess: process(to_shift_clk, reset)
    begin
        if reset = '1' then
            shift_reg <= "00000000";  
        elsif rising_edge(to_shift_clk) then
            case state is
                when init | zero_and_zero =>
                    shift_reg <= "00000000";  
                when rwin | lwin =>
                    shift_reg <= left_score & right_score;
                when r_shift =>
					if ballComing = '1' then
						shift_reg <= "10000000";  
					else
						shift_reg <= '0' & shift_reg(7 downto 1);
					end if;
                when l_shift =>
					if ballComing = '1' then
						shift_reg <= "00000001";  
				    else
						shift_reg <=shift_reg(6 downto 0) & '0';
					end if;
                when others =>
                    shift_reg <= "00000000";
            end case;
        end if;
    end process ledProcess;
    led_output<=shift_reg;
	
	--左右得分旗號處理 , processOfRALGF : process Of Right And Left Goal Flag 
	processOfRALGF:process(clock, reset)
	begin
		if reset = '1' then
			lsToRwin <= '0';
			rsToLwin <= '0';
		elsif rising_edge(clock) then
			case state is
				when init | zero_and_zero | rwin | lwin =>
					lsToRwin <= '0';
					rsToLwin <= '0';
				when r_shift =>
					if shift_reg = "00000001" then
						rsToLwin <= '1';
					else
						rsToLwin <= '0';
					end if;
				when l_shift =>
					if shift_reg = "10000000" then
						lsToRwin <= '1';
					else
						lsToRwin <= '0';
					end if;
				when others =>
					lsToRwin <= '0';
					rsToLwin <= '0';
			end case;
		end if;
	end process processOfRALGF;
	
	--分數處理
    score_process: process(clock, reset)
    begin
        if reset = '1' then
            right_score<= (others=>'0');
            left_score<= (others=>'0');     
        elsif rising_edge(clock) then
            case state is
                when init | zero_and_zero =>
                    right_score<= (others=>'0');
					left_score<= (others=>'0'); 
                when rwin | lwin =>
					null;
                when r_shift =>         
                    if ( right_player_button = '1' and shift_reg /= "00000001" ) or ( shift_reg = "00000000" and rsToLwin = '1' ) then
						left_score <= left_score + '1';
					else
						null;
					end if;	
                when l_shift =>
                    if ( left_player_button = '1' and shift_reg /= "10000000" ) or ( shift_reg = "00000000" and lsToRwin = '1' ) then
						right_score <= right_score + '1';
					else
						null;
					end if;	
                when others=>
                    left_score <= "0000";  
                    right_score <= "0000";
            end case;    
        end if;
    end process score_process;   
	
	--ballComing Setting
	ballcomingSetting:process(clock, reset)
	begin
		if reset = '1' then
			ballComing <= '0';
		elsif clock = '1' and clock'event then
			case state is
				when init =>
					ballComing <= '0';
				when zero_and_zero | rwin | lwin =>
					if start_button = '1' then
						ballComing <= '1';
					else
						null;
					end if;
				when r_shift =>
					if shift_reg = "10000000" then
						ballComing <= '0';
					else
						null;
					end if;
				when l_shift =>
					if shift_reg = "00000001" then
						ballComing <= '0';
					else
						null;
					end if;
				when others =>
					ballComing <= '0';
			end case;
		end if;
	end process ballcomingSetting;
end Behavioral;
