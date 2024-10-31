library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

--題目要求:兩個計數器 可外部設定上下限 一個數到上限 換另一個數到下限 循環動作 
entity ex1 is
    Port ( i_clk : in std_logic;
           i_rst : in std_logic;
		   i_upLim:in std_logic_vector(3 downto 0);
		   i_downLim:in std_logic_vector(3 downto 0);
           o_cnt : out std_logic_vector(7 downto 0)
		 );
end ex1;

architecture Behavioral of ex1 is
	signal div_cnt:std_logic_vector(26 downto 0);
	signal cnt_clk:std_logic;
	signal cnt1:std_logic_vector(3 downto 0); --計數器 1
	signal cnt2:std_logic_vector(3 downto 0); --計數器 2
	signal state:std_logic; --計數器狀態 狀態 0計數器 1上數，狀態 1計數器 2上數
	signal nextState:std_logic; --是否切換狀態的依據
	signal preNextState:std_logic; --紀錄前一個 nextState，用於與 nextState比較 若為 01表示需切換狀態
begin
	div_clk:process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			div_cnt <= (others => '0');
		elsif i_clk = '1' and i_clk'event then
			div_cnt <= div_cnt + '1';
		end if;
	end process div_clk;
	cnt_clk <= div_cnt(1);
	
	fsm:process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			state <= '0';
		elsif i_clk = '1' and i_clk'event then
			if preNextState = '0' and nextState = '1' then
				state <= not state;
			else
				null;
			end if;
		end if;
	end process fsm;
	
	cnt_process:process(cnt_clk, i_rst)
	begin
		if i_rst = '1' then
			cnt1 <= i_downLim;
			cnt2 <= i_upLim;
		elsif cnt_clk = '1' and cnt_clk'event then
			case state is
				when '0' =>
					if cnt1 >= i_upLim then
						cnt1 <= i_downLim;
					else
						cnt1 <= cnt1 + '1'; 
					end if;
				when '1' =>
					if cnt2 <= i_downLim then
						cnt2 <= i_upLim;
					else
						cnt2 <= cnt2 - '1'; 
					end if;
				when others =>
					cnt1 <= i_downLim;
					cnt2 <= i_upLim;
			end case;
		end if;
	end process cnt_process;
	o_cnt <= cnt2 & cnt1;
	
	--nextstate 處理
	ns_process:process(cnt_clk, i_rst)
	begin
		if i_rst ='1' then
			nextState <= '0';
		elsif cnt_clk = '1' and cnt_clk'event then
			case nextState is
				when '0' =>
					if cnt1 >= i_upLim or cnt2 <= i_downLim then
						nextState <= not nextState ;
					else
						null;
					end if;
				when '1' =>
					nextState <= not nextState ;
				when others =>
					nextState <= '0';
			end case;	
		end if;
	end process ns_process;
	
	--preNextState 處理
	prens_process:process(i_clk, i_rst)
	begin
		if i_rst ='1' then
			preNextState <= '0';
		elsif i_clk = '1' and i_clk'event then
			preNextState <= nextState;
		end if;
	end process prens_process;
end Behavioral;