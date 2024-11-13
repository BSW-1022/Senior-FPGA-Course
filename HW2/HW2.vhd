--題目說明:設計 PWM訊號模擬 DC Motor 目標速度 :100 初始速度 :0 門檻:80 
--第一階段 PWM輸出 1 100% 把速度加到門檻
--第二階段: PWM輸出 1 75%、0 25% 把速度加到大於目標速度 100
--第三階段: PPM輸出 1 25%、0 75% 把速度降到目標速度 100附近
--第四階段: PWM輸出 1 50%、0 50% 速度維持
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity HW2 is
    Port ( i_clock:in STD_LOGIC;
           i_reset:in STD_LOGIC;
           o_led:out STD_LOGIC
		 );
end HW2;

architecture Behavioral of HW2 is
	signal divCnt:std_logic_vector (26 downto 0):= (others => '0');
	signal speedClk:std_logic:= '0';
	signal speed:std_logic_vector(7 downto 0) := (others => '0');
	signal limit:std_logic_vector(6 downto 0) := "1010000";
	signal reach:std_logic_vector(6 downto 0) := "1100100";
	signal cnt1Up:std_logic_vector(7 downto 0) := (others => '0');
	signal cnt2Up:std_logic_vector(7 downto 0) := (others => '0');
	signal cnt1:std_logic_vector(7 downto 0) := (others => '0');
	signal cnt2:std_logic_vector(7 downto 0) := (others => '0');
	signal cntState:std_logic; --計數器狀態 狀態 1計數器 1數，狀態 0計數器 2數
	signal nextState:std_logic; --是否切換狀態的依據
	signal preNextState:std_logic; --紀錄前一個 nextState，用於與 nextState比較 若為 01表示需切換狀態
	type DC_MOTOR_STATE_TYPE is (INIT, FULLSPEED, ACCELERATE, SLOW_DOWN, MAINTAIN);
	signal DC_MOTOR_STATE : DC_MOTOR_STATE_TYPE := INIT;
begin
	o_led <= cntState;
	
	--降頻處理
	divclock:process(i_clock ,i_reset)
	begin
		if i_reset = '1' then
			divCnt <= (others => '0');
		elsif i_clock ='1' and i_clock'event then
			divCnt <= divCnt + '1';
		end if;
	end process divclock;
	speedClk <= divCnt(2);
	
	--馬達狀態，dcmtrst= DC_MOTOR_STATE
	dcmtrst:process(i_clock ,i_reset)
	begin
		if i_reset = '1' then
			DC_MOTOR_STATE <= INIT;
		elsif i_clock = '1' and i_clock'event then
			case DC_MOTOR_STATE is 
				when INIT =>
					DC_MOTOR_STATE <= FULLSPEED;
				when FULLSPEED =>
					if cntState = '1' and preNextState = '0' and nextState = '1' then
						DC_MOTOR_STATE <= ACCELERATE;
					else
						null;
					end if;
				when ACCELERATE =>
					if cntState = '1' and preNextState = '0' and nextState = '1' then
						DC_MOTOR_STATE <= SLOW_DOWN;
					else
						null;
					end if;
				when SLOW_DOWN =>
					if cntState = '1' and preNextState = '0' and nextState = '1' then
						DC_MOTOR_STATE <= MAINTAIN;
					else
						null;
					end if;
				when MAINTAIN =>
					null;
				when others =>
					DC_MOTOR_STATE <= INIT;
			end case;
		end if;
	end process dcmtrst;
	
	--計數器狀態，cst =cntState
	cst:process(i_clock, i_reset)
	begin
		if i_reset = '1' then
			cntState <= '0';
		elsif i_clock = '1' and i_clock'event then
			if preNextState = '0' and nextState = '1' then
				cntState <= not cntState;
			else
				null;
			end if;
		end if;
	end process cst;
	
	--nextstate處理，ns= nextstate
	ns_process:process(speedClk, i_reset)
	begin
		if i_reset ='1' then
			nextState <= '0';
		elsif speedClk = '1' and speedClk'event then
			case cntState is
				when '0' =>
					if cnt2 >= cnt2Up then
						nextState <= not nextState;
					else
						if nextState = '1' then
							nextState <= not nextState;
						else
							null;
						end if;
					end if;
				when '1' =>
					if cnt1 >= cnt1Up then
						nextState <= not nextState;
					else
						if nextState = '1' then
							nextState <= not nextState;
						else
							null;
						end if;
					end if;
				when others =>
					nextState <= '0';
			end case;	
		end if;
	end process ns_process;
	
	--preNextState處理，prens= preNextState
	prens_process:process(i_clock, i_reset)
	begin
		if i_reset ='1' then
			preNextState <= '0';
		elsif i_clock = '1' and i_clock'event then
			preNextState <= nextState;
		end if;
	end process prens_process;
	
	--計數器上限設定
	cnt_up_set:process(i_clock ,i_reset)
	begin
		if i_reset = '1' then
			cnt1Up <= (others => '0');
			cnt2Up <= (others => '0');
		elsif i_clock = '1' and i_clock'event then
			case DC_MOTOR_STATE is
				when INIT =>
					cnt1Up <= (others => '0');
					cnt2Up <= (others => '0');
				when FULLSPEED =>
					cnt1Up <= "11111111";      --255
				when ACCELERATE =>
					cnt1Up <= "10111111";      --191
					cnt2Up <= "00111111";      --63
				when SLOW_DOWN =>
					cnt1Up <= "00111111";	   --63
					cnt2Up <= "10111111";      --191
				when MAINTAIN =>
					cnt1Up <= "01111111";      --127
					cnt2Up <= "01111111";      --127
				when others =>
					cnt1Up <= (others => '0');
					cnt2Up <= (others => '0');
			end case;
		end if;
	end process cnt_up_set;
	
	--速度處理
	speed_process:process(speedClk ,i_reset)
	begin
		if i_reset = '1' then
			speed <= (others => '0');
		elsif speedClk ='1' and speedClk'event then
			case DC_MOTOR_STATE is
				when INIT =>
					speed <= (others => '0');
				when FULLSPEED =>
					if cntState = '0' then
						null;
					else
						if speed = "01010000" then --80
							null;
						else
							speed <= speed + '1';
						end if;
					end if;
				when ACCELERATE =>
					if cntState = '0' then
						if speed = "00110111" then --55
							null;
						else
							speed <= speed - '1';
						end if;
					else
						if speed = "10000010" then --130
							null;
						else
							speed <= speed + '1';
						end if;
					end if;
				when SLOW_DOWN | MAINTAIN =>
					if cntState = '0' then
						if speed = "01100010" then --98
							null;
						else
							speed <= speed - '1';
						end if;
					else
						if speed = "01100110" then --102
							null;
						else
							speed <= speed + '1';
						end if;
					end if;
				when others =>
					speed <= (others => '0');
			end case;
		end if; 
	end process;
	
	--計數器處理
	cnt_process:process(speedClk, i_reset)
	begin
		if i_reset = '1' then
			cnt1 <= (others => '0');
			cnt2 <= (others => '0');
		elsif speedClk = '1' and speedClk'event then
			case cntState is
				when '0' =>
					if cnt2 >= cnt2Up then
						cnt2 <= (others => '0');
					else
						cnt2 <= cnt2 + '1'; 
					end if;
				when '1' =>
					if cnt1 >= cnt1Up then
						cnt1 <= (others => '0');
					else
						cnt1 <= cnt1 + '1'; 
					end if;
				when others =>
					cnt1 <= (others => '0');
					cnt2 <= (others => '0');
			end case;
		end if;
	end process cnt_process;
	
end Behavioral;