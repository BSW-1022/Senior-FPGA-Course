--顯示三個不同顏色的方塊
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA is
	Port (clock : in STD_LOGIC;						    --系統時脈
          reset : in STD_LOGIC;						    --初始化按鈕
          color_btn : in STD_LOGIC_VECTOR (2 downto 0); --顏色選擇按鈕 100紅色 010綠色 001 藍色
          ledout:out STD_LOGIC_VECTOR (2 downto 0);     --顯示顏色選擇按鈕的 1 0 狀況，使用 LED
          o_red : out STD_LOGIC_VECTOR (3 downto 0);    --VGA的 Red訊號
          o_green : out STD_LOGIC_VECTOR (3 downto 0);  --VGA的 Green訊號
          o_blue : out STD_LOGIC_VECTOR (3 downto 0);   --VGA的 Blue訊號
          o_hs : out STD_LOGIC; 						--VGA的水平訊號
          o_vs : out STD_LOGIC						    --VGA的垂直訊號
		  );
end VGA;
architecture Behavioral of VGA is
	signal clk_div_cnt:std_logic_vector(26 downto 0):= (others => '0'); --除頻counter
    signal to_vga_clk:std_logic:='0'; --給vga的時脈 
    --以下VGA參數
    constant C_H_SYNC_PULSE : integer := 96;
    constant C_H_BACK_PORCH : integer := 48;
    constant C_H_ACTIVE_TIME : integer := 640;
    constant C_H_LINE_PERIOD : integer := 800; --整個水平訊號的週期 包含 Front Porch
    
    constant C_V_SYNC_PULSE : integer := 2;
    constant C_V_BACK_PORCH : integer := 33;
    constant C_V_ACTIVE_TIME : integer := 480;
    constant C_V_FRAME_PERIOD : integer := 525; --整個垂直訊號的週期 包含 Front Porch
    
    constant C_COLOR_BAR_WIDTH : integer := C_H_ACTIVE_TIME;
    
    signal R_h_cnt : integer := 0;
    signal R_v_cnt : integer := 0;
    signal W_active_flag : STD_LOGIC; --Actice旗號，功能:判斷是否在螢幕範圍內  
begin
	--除頻處理
    div_clk:process(clock,reset)
    begin
        if reset='1' then
            clk_div_cnt<= (others=>'0');
        elsif clock='1' and clock'event then
            clk_div_cnt <= clk_div_cnt + '1';
        end if;
    end process div_clk;
    to_vga_clk<=clk_div_cnt(1);

	--水平訊號處理
    horizontal_process:process(to_vga_clk, reset)
    begin
        if reset = '1' then
            R_h_cnt <= 0;
        elsif rising_edge(to_vga_clk) then
            if R_h_cnt = C_H_LINE_PERIOD - 1 then
                R_h_cnt <= 0;
            else
                R_h_cnt <= R_h_cnt + 1;
            end if;
        end if;
    end process horizontal_process;
    o_hs <= '0' when R_h_cnt < C_H_SYNC_PULSE else '1';
    
    --垂直訊號處理
    vertical_process:process(to_vga_clk, reset)
    begin
        if reset = '1' then
            R_v_cnt <= 0;
        elsif rising_edge(to_vga_clk) then
            if R_v_cnt = C_V_FRAME_PERIOD - 1 then
                R_v_cnt <= 0;
            elsif R_h_cnt = C_H_LINE_PERIOD - 1 then
                R_v_cnt <= R_v_cnt + 1;
			else
				null;
            end if;
        end if;
    end process vertical_process;
    o_vs <= '0' when R_v_cnt < C_V_SYNC_PULSE else '1';
    
    W_active_flag <= '1' when (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH) and
                               R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME) and
                               R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH) and
                               R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME)) else '0';
							  
	--VGA輸出處理
	vga_output:process(to_vga_clk, reset)
    begin
        if reset = '1' then
            o_red <= (others => '0');
            o_green <= (others => '0');
            o_blue <= (others => '0');
        elsif rising_edge(to_vga_clk) then
            --判斷是否在螢幕範圍內
			if W_active_flag = '1' then
				--在螢幕範圍內，根據H_cnt判斷是否在顯示的方塊畫面內				
				case R_h_cnt is
					when C_H_SYNC_PULSE + C_H_BACK_PORCH + 100 to C_H_SYNC_PULSE + C_H_BACK_PORCH + 200 =>
						if R_v_cnt >= C_V_SYNC_PULSE + C_V_BACK_PORCH + 100 and R_v_cnt <= C_V_SYNC_PULSE + C_V_BACK_PORCH + 200 then
							if color_btn(2) = '1' then
								o_red <= "1111";
								o_green <= "0000";
								o_blue <= "0000";
							else
								o_red <= "1111";
								o_green <= "1111";
								o_blue <= "1111";
							end if;
						else
							o_red <= (others => '0');
							o_green <= (others => '0');
							o_blue <= (others => '0');
						end if;
					when C_H_SYNC_PULSE + C_H_BACK_PORCH + 250 to C_H_SYNC_PULSE + C_H_BACK_PORCH + 350 =>
						if R_v_cnt >= C_V_SYNC_PULSE + C_V_BACK_PORCH + 100 and R_v_cnt <= C_V_SYNC_PULSE + C_V_BACK_PORCH + 200 then
							if color_btn(1) = '1' then
								o_red <= "0000";
								o_green <= "1111";
								o_blue <= "0000";
							else
								o_red <= "0000";
								o_green <= "1111";
								o_blue <= "1111";
							end if;
						else
							o_red <= (others => '0');
							o_green <= (others => '0');
							o_blue <= (others => '0');
						end if;
					when C_H_SYNC_PULSE + C_H_BACK_PORCH + 400 to C_H_SYNC_PULSE + C_H_BACK_PORCH + 500 =>
						if R_v_cnt >= C_V_SYNC_PULSE + C_V_BACK_PORCH + 100 and R_v_cnt <= C_V_SYNC_PULSE + C_V_BACK_PORCH + 200 then
							if color_btn(0) = '1' then
								o_red <= "0000";
								o_green <= "0000";
								o_blue <= "1111";
							else
								o_red <= "1111";
								o_green <= "0000";
								o_blue <= "1111";
							end if;
						else
							o_red <= (others => '0');
							o_green <= (others => '0');
							o_blue <= (others => '0');
						end if;
					when others =>
						o_red <= (others => '0');
						o_green <= (others => '0');
						o_blue <= (others => '0');
                end case;
            else
				--螢幕範圍以外輸出黑色
                o_red <= (others => '0');
                o_green <= (others => '0');
                o_blue <= (others => '0');
            end if;
        end if;            
    end process vga_output;
    ledout<=color_btn;						 
end Behavioral;
